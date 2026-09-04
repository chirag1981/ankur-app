import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

// Search and Filter providers
final customerSearchQueryProvider = StateProvider<String>((ref) => '');
final customerStatusFilterProvider = StateProvider<String>((ref) => 'all');

// Customer List Provider
final customerListProvider = FutureProvider<List<Customer>>((ref) async {
  final query = ref.watch(customerSearchQueryProvider);
  final filter = ref.watch(customerStatusFilterProvider);
  final db = DatabaseHelper.instance;
  return await db.getAllCustomers(
    searchQuery: query,
    statusFilter: filter,
  );
});

// Single Customer Estimate Provider
final customerEstimateProvider = FutureProvider.family<CustomerEstimate?, int>((ref, customerId) async {
  final db = DatabaseHelper.instance;
  return await db.getCompleteCustomerEstimate(customerId);
});

// Master Materials Provider
final masterMaterialsProvider = FutureProvider<List<MaterialItem>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getMasterMaterials();
});

// Company Profile Provider
final companyProfileProvider = FutureProvider<CompanyProfile>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getCompanyProfile();
});

// Customer Controller for Actions
final customerControllerProvider = Provider((ref) => CustomerController(ref));

class CustomerController {
  final Ref ref;
  final DatabaseHelper _db = DatabaseHelper.instance;

  CustomerController(this.ref);

  Future<void> updateCompanyProfile(CompanyProfile profile) async {
    await _db.updateCompanyProfile(profile);
    ref.invalidate(companyProfileProvider);
  }

  Future<int> createCustomer(Customer customer) async {
    final id = await _db.insertCustomer(customer);
    ref.invalidate(customerListProvider);
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    ref.invalidate(customerListProvider);
    if (customer.id != null) {
      ref.invalidate(customerEstimateProvider(customer.id!));
    }
  }

  Future<void> deleteCustomer(int customerId) async {
    await _db.deleteCustomer(customerId);
    ref.invalidate(customerListProvider);
  }

  // Room operations
  Future<int> addRoom({required int customerId, required String name, String notes = ''}) async {
    final room = Room(customerId: customerId, name: name, notes: notes);
    final id = await _db.insertRoom(room);
    ref.invalidate(customerEstimateProvider(customerId));
    ref.invalidate(customerListProvider);
    return id;
  }

  Future<void> updateRoom(Room room) async {
    await _db.updateRoom(room);
    ref.invalidate(customerEstimateProvider(room.customerId));
  }

  Future<void> deleteRoom(int roomId, int customerId) async {
    await _db.deleteRoom(roomId);
    ref.invalidate(customerEstimateProvider(customerId));
    ref.invalidate(customerListProvider);
  }

  // Window operations
  Future<int> addWindow(WindowItem window) async {
    final id = await _db.insertWindow(window);
    ref.invalidate(customerEstimateProvider(window.customerId));
    ref.invalidate(customerListProvider);
    return id;
  }

  Future<void> updateWindow(WindowItem window) async {
    await _db.updateWindow(window);
    ref.invalidate(customerEstimateProvider(window.customerId));
    ref.invalidate(customerListProvider);
  }

  Future<void> deleteWindow(int windowId, int customerId) async {
    await _db.deleteWindow(windowId);
    ref.invalidate(customerEstimateProvider(customerId));
    ref.invalidate(customerListProvider);
  }

  // Material operations
  Future<void> updateMaterial(MaterialItem material) async {
    await _db.updateMaterial(material);
    if (material.customerId != null) {
      ref.invalidate(customerEstimateProvider(material.customerId!));
    } else {
      ref.invalidate(masterMaterialsProvider);
    }
  }

  Future<void> addMaterial(MaterialItem material) async {
    await _db.insertMaterial(material);
    if (material.customerId != null) {
      ref.invalidate(customerEstimateProvider(material.customerId!));
    } else {
      ref.invalidate(masterMaterialsProvider);
    }
  }

  Future<void> deleteMaterial(int materialId, int? customerId) async {
    await _db.deleteMaterial(materialId);
    if (customerId != null) {
      ref.invalidate(customerEstimateProvider(customerId));
    } else {
      ref.invalidate(masterMaterialsProvider);
    }
  }

  // Quick helper to update discount, advance, profit margin, or tax
  Future<void> updatePricing({
    required Customer customer,
    required String discountType,
    required double discountValue,
    required double advanceAmount,
    double? taxRate,
    double? profitMarginRate,
    required String status,
  }) async {
    final updated = customer.copyWith(
      discountType: discountType,
      discountValue: discountValue,
      advanceAmount: advanceAmount,
      taxRate: taxRate ?? customer.taxRate,
      profitMarginRate: profitMarginRate ?? customer.profitMarginRate,
      status: status,
    );
    await updateCustomer(updated);
  }
}
