import 'package:flutter/foundation.dart';

import '../../data/pos_repository.dart';
import '../../domain/pos_models.dart';
import '../../domain/value_objects/money.dart';

/// Holds the working POS state for a single cashier: the product catalogue,
/// the current category/search filter, and the live cart.
class PosController extends ChangeNotifier {
  PosController({required this.repository});

  final PosRepository repository;

  /// Order-level tax rate (0 = no tax). Structured for a future settings hook.
  static const double taxRate = 0.0;

  List<PosProduct> _allProducts = [];
  final List<CartLine> _cart = [];

  bool _loading = false;
  String? _error;
  String _search = '';
  String? _category; // null => all categories
  Money _discount = Money.zero();

  bool get isLoading => _loading;
  String? get error => _error;
  String get search => _search;
  String? get category => _category;
  Money get discount => _discount;

  List<CartLine> get cart => List.unmodifiable(_cart);
  bool get isCartEmpty => _cart.isEmpty;
  int get cartItemCount => _cart.fold(0, (sum, line) => sum + line.quantity);

  List<String> get categories {
    final set = <String>{for (final p in _allProducts) p.category};
    final list = set.toList()..sort();
    return list;
  }

  List<PosProduct> get visibleProducts {
    final query = _search.trim().toLowerCase();
    return _allProducts.where((product) {
      final matchesCategory =
          _category == null || product.category == _category;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Money get subtotal => sumMoney(_cart.map((line) => line.lineTotal));
  Money get discountAmount => _discount.clamp(Money.zero(), subtotal);
  Money get taxAmount =>
      subtotal.subtract(discountAmount).multiply(taxRate).rounded();
  Money get total => subtotal.subtract(discountAmount).add(taxAmount);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _allProducts = await repository.loadProducts();
    } catch (e) {
      _error = 'Could not load products: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    _category = value;
    notifyListeners();
  }

  void setDiscount(Money value) {
    _discount = value.isNegative ? Money.zero() : value;
    notifyListeners();
  }

  /// Stock available to add for [product], accounting for what is already in the
  /// cart.
  int availableFor(PosProduct product) {
    final inCart = _cart
        .where((line) => line.product.id == product.id)
        .fold(0, (sum, line) => sum + line.quantity);
    return product.quantityOnHand - inCart;
  }

  /// Adds one unit of [product]; returns false if no stock remains.
  bool addProduct(PosProduct product) {
    if (availableFor(product) <= 0) return false;
    final index = _cart.indexWhere((line) => line.product.id == product.id);
    if (index >= 0) {
      _cart[index].quantity += 1;
    } else {
      _cart.add(CartLine(product: product, quantity: 1));
    }
    notifyListeners();
    return true;
  }

  bool increment(CartLine line) {
    if (availableFor(line.product) <= 0) return false;
    line.quantity += 1;
    notifyListeners();
    return true;
  }

  void decrement(CartLine line) {
    line.quantity -= 1;
    if (line.quantity <= 0) {
      _cart.removeWhere((l) => l.product.id == line.product.id);
    }
    notifyListeners();
  }

  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _cart.removeWhere((l) => l.product.id == line.product.id);
    } else {
      line.quantity = quantity.clamp(1, line.product.quantityOnHand);
    }
    notifyListeners();
  }

  void removeLine(CartLine line) {
    _cart.removeWhere((l) => l.product.id == line.product.id);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discount = Money.zero();
    notifyListeners();
  }

  /// Persists the sale via the repository, then refreshes stock and clears the
  /// cart. Throws [PosException] / [InsufficientStockException] on failure.
  Future<PosReceipt> checkout({
    required AppUser cashier,
    required PosShift shift,
    required List<PosPayment> payments,
    required Money paidAmount,
    required Money changeAmount,
    String? customerName,
  }) async {
    final request = CheckoutRequest(
      cashier: cashier,
      shift: shift,
      lines: _cart
          .map(
            (line) => CartLine(product: line.product, quantity: line.quantity),
          )
          .toList(),
      payments: payments,
      subtotal: subtotal,
      discount: discountAmount,
      tax: taxAmount,
      total: total,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      customerName: customerName,
    );
    final receipt = await repository.checkout(request);
    clearCart();
    await load();
    return receipt;
  }
}
