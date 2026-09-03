import 'package:flutter_test/flutter_test.dart';
import 'package:invisible_grills/core/utils/unit_converter.dart';
import 'package:invisible_grills/models/models.dart';

void main() {
  group('UnitConverter Tests', () {
    test('48" x 60" converts to 4.0 ft x 5.0 ft and 20.0 sq.ft', () {
      final widthFt = UnitConverter.inchesToFeet(48.0);
      final heightFt = UnitConverter.inchesToFeet(60.0);
      final sqFt = UnitConverter.calculateSqFt(
        widthInches: 48.0,
        heightInches: 60.0,
        quantity: 1,
      );

      expect(widthFt, equals(4.0));
      expect(heightFt, equals(5.0));
      expect(sqFt, equals(20.0));
    });

    test('36" x 48" with quantity 2 calculates 24.0 total sq.ft', () {
      final sqFt = UnitConverter.calculateSqFt(
        widthInches: 36.0,
        heightInches: 48.0,
        quantity: 2,
      );

      expect(sqFt, equals(24.0));
    });

    test('WindowItem model computes properties accurately', () {
      final window = WindowItem(
        roomId: 1,
        customerId: 1,
        label: 'Balcony Window',
        widthInches: 72.0, // 6 ft
        heightInches: 84.0, // 7 ft
        quantity: 1,
      );

      expect(window.widthFeet, equals(6.0));
      expect(window.heightFeet, equals(7.0));
      expect(window.sqFtPerUnit, equals(42.0));
      expect(window.totalSqFt, equals(42.0));
      expect(window.perimeterFeet, equals(26.0)); // 2 * (6 + 7)
    });

    test('MaterialItem automatically calculates cost based on total sq ft', () {
      final channel = MaterialItem(
        name: 'Aluminium 3-Track Section',
        unitPrice: 150.0,
        calculationType: 'per_sq_ft',
      );

      final totalCost = channel.getTotalCost(
        totalSqFt: 100.0,
        totalWindows: 2,
      );

      expect(totalCost, equals(15000.0));
    });

    test('Labor cost is automatically measured on total sq ft at 20rs per sq ft', () {
      final labor = MaterialItem(
        name: 'Labor',
        category: 'Labor',
        unit: 'Sq. Ft',
        unitPrice: 20.0,
        calculationType: 'per_sq_ft',
      );

      expect(labor.calculationType, equals('per_sq_ft'));
      expect(labor.unitPrice, equals(20.0));

      final effectiveQty = labor.getEffectiveQuantity(
        totalSqFt: 50.0,
        totalWindows: 2,
      );
      final totalLaborCost = labor.getTotalCost(
        totalSqFt: 50.0,
        totalWindows: 2,
      );

      expect(effectiveQty, equals(50.0));
      expect(totalLaborCost, equals(1000.0)); // 50 sq ft * 20 Rs = 1000 Rs
    });

    test('CustomerEstimate aggregates multiple rooms and calculates discount properly', () {
      final customer = Customer(
        id: 1,
        name: 'Test Customer',
        phone: '9876543210',
        discountType: 'percentage',
        discountValue: 10.0, // 10%
        advanceAmount: 2000.0,
      );

      final rooms = [
        Room(id: 1, customerId: 1, name: 'Living Room'),
        Room(id: 2, customerId: 1, name: 'Kitchen'),
      ];

      final windowsByRoom = {
        1: [
          WindowItem(
            id: 1,
            roomId: 1,
            customerId: 1,
            label: 'W1',
            widthInches: 48,
            heightInches: 60,
            quantity: 1,
          ), // 20 sq ft
        ],
        2: [
          WindowItem(
            id: 2,
            roomId: 2,
            customerId: 1,
            label: 'W2',
            widthInches: 36,
            heightInches: 48,
            quantity: 1,
          ), // 12 sq ft
        ],
      };

      final materials = [
        MaterialItem(
          name: 'Channel',
          unitPrice: 100.0,
          calculationType: 'per_sq_ft',
        ),
      ];

      final estimate = CustomerEstimate(
        customer: customer,
        rooms: rooms,
        windowsByRoom: windowsByRoom,
        materials: materials,
      );

      expect(estimate.totalRoomsCount, equals(2));
      expect(estimate.totalWindowsCount, equals(2));
      expect(estimate.totalSqFt, equals(32.0)); // 20 + 12
      expect(estimate.materialsCost, equals(3200.0)); // 32 * 100
      expect(estimate.subtotal, equals(3200.0));
      expect(estimate.discountAmount, equals(320.0)); // 10% of 3200
      expect(estimate.netAmount, equals(2880.0));
      expect(estimate.grandTotal, equals(2880.0));
      expect(estimate.advancePaid, equals(2000.0));
      expect(estimate.balanceDue, equals(880.0));
    });
  });
}
