import 'package:flutter_test/flutter_test.dart';
import 'package:operix_mobile/src/domain/value_objects/money.dart';

void main() {
  group('Money', () {
    test('0.1 + 0.2 == 0.3 exactly (the double trap)', () {
      final sum = Money.of('0.1') + Money.of('0.2');
      expect(sum.toStorageString(), '0.30');
      expect(sum == Money.of('0.3'), isTrue);
      // sanity: the same op on doubles is NOT 0.3
      expect(0.1 + 0.2 == 0.3, isFalse);
    });

    test('subtract and negate', () {
      expect(
        (Money.of('100.00') - Money.of('30.00')).toStorageString(),
        '70.00',
      );
      expect((-Money.of('5.00')).toStorageString(), '-5.00');
    });

    test('multiply keeps 6-dp intermediate precision then rounds to 2', () {
      // 3 units @ 1.005 = 3.015 -> stored 3.02 (round half away from zero)
      final line = Money.of('1.005').multiply(3);
      expect(line.toStorageString(), '3.02');
    });

    test('percentage (14% VAT)', () {
      final tax = Money.of('1500.00').percentage('14');
      expect(tax.toStorageString(), '210.00');
    });

    test('divide guards against zero', () {
      expect(() => Money.of('10').divide(0), throwsArgumentError);
    });

    test('sumMoney over a list', () {
      final total = sumMoney([
        Money.of('10.50'),
        Money.of('4.25'),
        Money.of('0.25'),
      ]);
      expect(total.toStorageString(), '15.00');
    });

    test('clamp constrains to range (POS discount <= subtotal)', () {
      final subtotal = Money.of('80.00');
      final discount = Money.of('120.00').clamp(Money.zero(), subtotal);
      expect(discount, subtotal);
    });

    test('parse is lenient for db/json values', () {
      expect(Money.parse(null).isZero, isTrue);
      expect(Money.parse('').isZero, isTrue);
      expect(Money.parse('1234.5').toStorageString(), '1234.50');
      expect(Money.parse(42).toStorageString(), '42.00');
    });

    test('currency mismatch throws', () {
      expect(
        () => Money.of('1', 'EGP') + Money.of('1', 'USD'),
        throwsArgumentError,
      );
    });

    test('comparison operators', () {
      expect(Money.of('5.00') > Money.of('4.99'), isTrue);
      expect(Money.of('5.00') >= Money.of('5.00'), isTrue);
      expect(Money.of('5.00') < Money.of('5.01'), isTrue);
    });
  });
}
