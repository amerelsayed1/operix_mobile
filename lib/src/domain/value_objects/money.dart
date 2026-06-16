// Money value object — the offline mirror of the cloud's
// app/Domain/ValueObjects/Money.php.
//
// Why this exists: the cloud backend never uses floating point for money. It
// stores decimal(15,2) and computes with bcmath at 6-decimal intermediate
// precision, rounding to 2 decimals only when persisting. This class reproduces
// that contract in Dart so the offline app produces byte-identical financial
// results — which is what makes a future cloud<->offline sync safe.
//
// Kept free of Flutter / database imports so it can be shared across the UI,
// controllers, and repository implementations (same rule as the other domain
// models in this folder).

import 'package:decimal/decimal.dart';

/// An immutable monetary amount in a single currency.
///
/// All arithmetic returns a new [Money]; instances are never mutated. Intermediate
/// results (multiply/divide) are kept at [intermediateScale] decimals to match the
/// cloud's `bcmul/bcdiv(..., 6)`; call [rounded] (or [toStorageString]) to collapse
/// to the [storageScale] used by `decimal(15,2)` columns before persisting.
class Money implements Comparable<Money> {
  const Money._(this._amount, this.currency);

  /// Functional currency default. The offline product is single-tenant, so unless
  /// a transaction currency is given we treat amounts as the functional currency.
  static const String defaultCurrency = 'EGP';

  /// Working precision for multiply/divide — mirrors bcmath scale 6 in the cloud.
  static const int intermediateScale = 6;

  /// Persistence/display precision — mirrors `decimal(15,2)`.
  static const int storageScale = 2;

  final Decimal _amount;

  /// ISO 4217-style code (e.g. 'EGP', 'USD'). Operations require matching codes.
  final String currency;

  // --- Constructors ---------------------------------------------------------

  /// Builds from a decimal string, e.g. `Money.of('1500.00')` — mirrors
  /// `Money::of('1500.00', 'EGP')`.
  factory Money.of(String amount, [String currency = defaultCurrency]) =>
      Money._(Decimal.parse(amount), currency);

  /// A zero amount in [currency].
  factory Money.zero([String currency = defaultCurrency]) =>
      Money._(Decimal.zero, currency);

  /// Builds from a numeric literal. Routed through `toString()` so we never go
  /// near binary floating point (`Decimal.parse('0.1')`, not `0.1` the double).
  factory Money.fromNum(num amount, [String currency = defaultCurrency]) =>
      Money._(Decimal.parse(amount.toString()), currency);

  /// Lenient parse for values coming back from the database or JSON, which the
  /// postgres driver may hand us as a `String`, `num`, or already-[Money].
  /// `null`/empty becomes zero.
  factory Money.parse(Object? value, [String currency = defaultCurrency]) {
    if (value == null) return Money.zero(currency);
    if (value is Money) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return Money.zero(currency);
    // Tolerate malformed input (e.g. a column that unexpectedly returns
    // formatted text) by falling back to zero instead of throwing out of a
    // repository read path.
    final parsed = Decimal.tryParse(text);
    return Money._(parsed ?? Decimal.zero, currency);
  }

  // --- Accessors ------------------------------------------------------------

  /// The raw arbitrary-precision amount. Prefer the arithmetic methods over
  /// reaching for this.
  Decimal get value => _amount;

  /// Lossy conversion to double — for charting/widgets/DB-boundary only, never
  /// for posting arithmetic. The decimal(15,2) columns enforce scale on write.
  double toDouble() => _amount.toDouble();

  bool get isZero => _amount == Decimal.zero;
  bool get isNegative => _amount < Decimal.zero;
  bool get isPositive => _amount > Decimal.zero;

  // --- Arithmetic (immutable) ----------------------------------------------

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(_amount + other._amount, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money._(_amount - other._amount, currency);
  }

  Money operator -() => Money._(-_amount, currency);

  /// Adds another amount of the same currency.
  Money add(Money other) => this + other;

  /// Subtracts another amount of the same currency.
  Money subtract(Money other) => this - other;

  /// Multiplies by a scalar (qty, rate, percentage factor). Accepts `num`,
  /// `Decimal`, or a numeric `String`. Result rounded to [intermediateScale].
  Money multiply(Object factor) => Money._(
    _round(_amount * _toDecimal(factor), intermediateScale),
    currency,
  );

  /// Divides by a non-zero scalar. Result rounded to [intermediateScale].
  Money divide(Object divisor) {
    final d = _toDecimal(divisor);
    if (d == Decimal.zero) {
      throw ArgumentError('Money.divide: division by zero');
    }
    final quotient = (_amount / d).toDecimal(
      scaleOnInfinitePrecision: intermediateScale,
    );
    return Money._(_round(quotient, intermediateScale), currency);
  }

  /// Returns this amount as a percentage portion, e.g. `total.percentage('14')`
  /// for 14% VAT. Convenience over `multiply(rate).divide(100)`.
  Money percentage(Object rate) {
    final portion = (_amount * _toDecimal(rate) / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: intermediateScale);
    return Money._(_round(portion, intermediateScale), currency);
  }

  Money negate() => -this;

  /// Absolute value.
  Money abs() => isNegative ? Money._(-_amount, currency) : this;

  /// Constrains to `[min, max]` (used e.g. to clamp a POS discount to the subtotal).
  Money clamp(Money min, Money max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  // --- Rounding / formatting ------------------------------------------------

  /// Collapses to storage precision (2 dp). Apply before persisting or summing
  /// into a posted total — mirrors the cloud's final `round(..., 2)`.
  Money rounded() => Money._(_round(_amount, storageScale), currency);

  /// Storage string with exactly 2 decimals (e.g. `'1500.00'`) — what goes into
  /// a `decimal(15,2)` column.
  String toStorageString() =>
      _round(_amount, storageScale).toStringAsFixed(storageScale);

  // --- Comparison -----------------------------------------------------------

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return _amount.compareTo(other._amount);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Money && other.currency == currency && other._amount == _amount;

  @override
  int get hashCode => Object.hash(currency, _amount);

  @override
  String toString() => '${toStorageString()} $currency';

  // --- Internals ------------------------------------------------------------

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Money currency mismatch: $currency vs ${other.currency}. '
        'Convert to a common currency before combining.',
      );
    }
  }

  static Decimal _round(Decimal value, int scale) => value.round(scale: scale);

  static Decimal _toDecimal(Object value) {
    if (value is Decimal) return value;
    if (value is Money) return value._amount;
    if (value is int) return Decimal.fromInt(value);
    return Decimal.parse(value.toString());
  }
}

/// Sums a list of [Money]. The accumulator currency is taken from the first
/// element (falling back to [currency]) so a non-default-currency list doesn't
/// throw a spurious "currency mismatch" against a hardcoded EGP zero.
Money sumMoney(
  Iterable<Money> amounts, [
  String currency = Money.defaultCurrency,
]) {
  final iterator = amounts.iterator;
  if (!iterator.moveNext()) return Money.zero(currency);
  var total = iterator.current;
  while (iterator.moveNext()) {
    total = total + iterator.current;
  }
  return total;
}
