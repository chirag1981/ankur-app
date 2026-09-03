import 'customer.dart';
import 'room.dart';
import 'window_item.dart';
import 'material_item.dart';

class CustomerEstimate {
  final Customer customer;
  final List<Room> rooms;
  final Map<int, List<WindowItem>> windowsByRoom; // roomId -> windows
  final List<MaterialItem> materials;

  CustomerEstimate({
    required this.customer,
    required this.rooms,
    required this.windowsByRoom,
    required this.materials,
  });

  /// Flat list of all windows across all rooms for this customer
  List<WindowItem> get allWindows {
    final list = <WindowItem>[];
    for (final roomWindows in windowsByRoom.values) {
      list.addAll(roomWindows);
    }
    return list;
  }

  /// Total count of physical window units
  int get totalWindowsCount {
    return allWindows.fold(0, (sum, w) => sum + w.quantity);
  }

  /// Total Rooms count
  int get totalRoomsCount => rooms.length;

  /// Total Square Footage across all windows in all rooms
  double get totalSqFt {
    return allWindows.fold(0.0, (sum, w) => sum + w.totalSqFt);
  }

  /// Total perimeter in running feet across all windows
  double get totalPerimeterFeet {
    return allWindows.fold(0.0, (sum, w) => sum + w.perimeterFeet);
  }

  /// Total width in feet multiplied by 2 across all windows (top & bottom channel length)
  double get totalChannelWidthFeet {
    return allWindows.fold(0.0, (sum, w) => sum + (w.widthFeet * 2.0 * (w.quantity > 0 ? w.quantity : 1)));
  }

  /// Total 10ft channel bars used across all windows (ceil of totalChannelWidthFeet / 10)
  int get totalChannelsUsed {
    if (totalChannelWidthFeet <= 0) return 0;
    return (totalChannelWidthFeet / 10.0).ceil();
  }

  /// Total material cost calculated automatically
  double get materialsCost {
    final sqFt = totalSqFt;
    final winCount = totalWindowsCount;
    final channelFt = totalChannelWidthFeet;
    return materials.fold(0.0, (sum, item) {
      return sum + item.getTotalCost(
        totalSqFt: sqFt,
        totalWindows: winCount,
        totalChannelWidthFt: channelFt,
      );
    });
  }

  /// Subtotal (materials + any direct window rate if applicable)
  double get subtotal {
    final directWindowCosts = allWindows.fold(0.0, (sum, w) => sum + w.totalCost);
    return materialsCost + directWindowCosts;
  }

  /// Computed discount amount
  double get discountAmount {
    if (customer.discountType == 'percentage') {
      return subtotal * (customer.discountValue / 100.0);
    } else {
      return customer.discountValue;
    }
  }

  /// Amount after discount
  double get netAmount {
    final val = subtotal - discountAmount;
    return val > 0 ? val : 0.0;
  }

  /// Tax amount if tax rate is provided
  double get taxAmount {
    if (customer.taxRate <= 0) return 0.0;
    return netAmount * (customer.taxRate / 100.0);
  }

  /// Grand Total
  double get grandTotal => netAmount + taxAmount;

  /// Advance Paid
  double get advancePaid => customer.advanceAmount;

  /// Balance Due
  double get balanceDue {
    final bal = grandTotal - advancePaid;
    return bal > 0 ? bal : 0.0;
  }

  /// Returns total sq ft for a specific room
  double getRoomTotalSqFt(int roomId) {
    final roomWindows = windowsByRoom[roomId] ?? [];
    return roomWindows.fold(0.0, (sum, w) => sum + w.totalSqFt);
  }

  /// Returns total windows for a specific room
  int getRoomWindowsCount(int roomId) {
    final roomWindows = windowsByRoom[roomId] ?? [];
    return roomWindows.fold(0, (sum, w) => sum + w.quantity);
  }

  /// Returns total channel width in feet (width * 2) for a specific room
  double getRoomChannelWidthFeet(int roomId) {
    final roomWindows = windowsByRoom[roomId] ?? [];
    return roomWindows.fold(0.0, (sum, w) => sum + (w.widthFeet * 2.0 * (w.quantity > 0 ? w.quantity : 1)));
  }

  /// Returns total 10ft channel bars used for a specific room
  int getRoomChannelsUsed(int roomId) {
    final ft = getRoomChannelWidthFeet(roomId);
    if (ft <= 0) return 0;
    return (ft / 10.0).ceil();
  }
}
