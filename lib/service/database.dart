import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'package:collection/collection.dart';
import 'package:due_kasir/controller/inventory_controller.dart';
import 'package:due_kasir/controller/selling_controller.dart';
import 'package:due_kasir/main.dart';
import 'package:due_kasir/model/auth_model.dart';
import 'package:due_kasir/model/customer_model.dart';
import 'package:due_kasir/model/due_payment_model.dart';
import 'package:due_kasir/model/expenses_model.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/model/presence_model.dart';
import 'package:due_kasir/model/rent_item_model.dart';
import 'package:due_kasir/model/rent_model.dart';
import 'package:due_kasir/model/salary_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/model/user_model.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:due_kasir/utils/secure_storage_helper.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class MockAuth {
  dynamic get currentUser => null;
}
class MockSupabase {
  final auth = MockAuth();
}

class Database {
  late Future<Isar> db;
  static bool _structureEnsured = false;

  Database() {
    db = openDB();
  }

  final dynamic _supabaseHelper = null;
  static final dynamic supabase = MockSupabase();

  // Auth Local
  Future<void> loginUser(AuthModel val) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.authModels.putSync(val));
  }

  Future<void> changeUser(AuthModel val) async {
    final isar = await db;
    isar.writeTxn(() async {
      await isar.authModels.put(val);
      await val.user.save();
    });
  }

  // User
  Future<AuthModel> authUser() async {
    final isar = await db;
    IsarCollection<AuthModel> authCollection = isar.collection<AuthModel>();
    final users = await authCollection.where().findAll();
    getIt.get<SellingController>().kasir.value = users.first.user.value;
    return users.first;
  }

  Future<void> addNewUser(UserModel val) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.userModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addUsers(val.toJson());
    }
  }

  Future<void> deleteUser(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.userModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeUsers(val);
    }
  }

  Future<void> updateUser(UserModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() => isar.userModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateUsers(val);
    }
  }

  Future<List<UserModel>> getUsers({String? name}) async {
    final isar = await db;
    IsarCollection<UserModel> userCollection = isar.collection<UserModel>();
    final users = userCollection
        .filter()
        .namaContains(name ?? '', caseSensitive: false)
        .findAll();
    return users;
  }

  Future<UserModel?> getUserById(int id) async {
    final isar = await db;
    IsarCollection<UserModel> userCollection = isar.collection<UserModel>();
    final users = userCollection.get(id);
    return users;
  }

  Future<void> clearUser() async {
    final isar = await db;
    IsarCollection<CustomerModel> customerCollection =
        isar.collection<CustomerModel>();
    isar.writeTxn<void>(() => customerCollection.clear());
  }

  insertUserFresh(List<UserModel> userList) async {
    final isar = await db;
    await clearUser();
    if (userList.isNotEmpty) {
      await Future.forEach(
          userList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.userModels.put(val)));
      await getUsers();
    }
  }

  Future<void> syncUsers() async {
    final users = await getUsers();
    if (users.isNotEmpty) {
      await Future.forEach(users, (element) async {
        final res = await _supabaseHelper.getUserById(element.id!);
        if (res == false) {
          _supabaseHelper.addUsers(element.toJson());
        }
      });
      final res = await _supabaseHelper.getUsers();
      if (res.isNotEmpty) {
        await insertUserFresh(res);
      }
    } else {
      final res = await _supabaseHelper.getUsers();
      if (res.isNotEmpty) {
        await insertUserFresh(res);
      }
    }
  }

  // Customer
  Future<void> addNewCustomer(CustomerModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.customerModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addCustomer(val.toJson());
    }
  }

  Future<void> deleteCustomer(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.customerModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeCustomer(val);
    }
  }

  Future<void> updateCustomer(CustomerModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() async => await isar.customerModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateCustomer(val);
    }
  }

  Future<List<CustomerModel>> getCustomers({String? name}) async {
    final isar = await db;
    IsarCollection<CustomerModel> customerCollection =
        isar.collection<CustomerModel>();
    final customer = customerCollection
        .filter()
        .namaContains(name ?? '', caseSensitive: false)
        .findAll();
    return customer;
  }

  Future<void> syncCustomers() async {
    final customers = await getCustomers();
    if (customers.isNotEmpty) {
      await Future.forEach(customers, (val) async {
        final res = await _supabaseHelper.getCustomerById(val.id!);
        if (res == false) {
          await _supabaseHelper.addCustomer(val.toJson());
        }
      });
      final res = await _supabaseHelper.getCustomerAll();
      if (res.isNotEmpty) {
        await insertCustomerFresh(res);
      }
    } else {
      final res = await _supabaseHelper.getCustomerAll();
      if (res.isNotEmpty) {
        await insertCustomerFresh(res);
      }
    }
  }

  Future<void> clearCustomer() async {
    final isar = await db;
    IsarCollection<CustomerModel> customerCollection =
        isar.collection<CustomerModel>();
    isar.writeTxn<void>(() => customerCollection.clear());
  }

  insertCustomerFresh(List<CustomerModel> customerList) async {
    final isar = await db;
    await clearCustomer();
    if (customerList.isNotEmpty) {
      await Future.forEach(
          customerList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.customerModels.put(val)));
    }
    await getCustomers();
  }

  Future<void> checkCustomerSynced() async {
    final customers = await getCustomers();
    if (customers.isNotEmpty) {
      for (CustomerModel element in customers) {
        final res = await _supabaseHelper.getCustomerById(element.id!);
        if (res == false) {
          _supabaseHelper.addCustomer(element.toJson());
        }
      }
    } else {
      getCustomers();
    }
  }

  Future<CustomerModel?> getCustomerById(int id) async {
    final isar = await db;
    IsarCollection<CustomerModel> customerCollection =
        isar.collection<CustomerModel>();
    final users = customerCollection.get(id);
    return users;
  }

  // inventory
  Future<void> addInventory(ItemModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.itemModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addInventory(val.toJson());
    }
  }

  Future<void> addAllInventory(List<ItemModel> vals) async {
    final isar = await db;
    for (var val in vals) {
      val.isSynced =
          isDeviceConnected.value && supabase.auth.currentUser != null;
      isar.writeTxnSync<int>(() => isar.itemModels.putSync(val));
      if (isDeviceConnected.value && supabase.auth.currentUser != null) {
        _supabaseHelper.addInventory(val.toJson());
      }
    }
  }

  Future<void> deleteInventory(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.itemModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeInventory(val);
    }
  }

  Future<void> updateInventory(ItemModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() async => await isar.itemModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateInventory(val);
    }
  }

  Future<List<ItemModel>> getInventorys({String? value}) async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    return await inventoryCollection
        .filter()
        .group((q) => q
            .namaContains(value ?? '', caseSensitive: false)
            .or()
            .codeContains(value ?? '', caseSensitive: false))
        .findAll();
  }

  Future<void> adjustInventory({
    required int itemId,
    required int change,
    required String reason,
    required String type,
  }) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final item = await isar.itemModels.get(itemId);
      if (item == null) throw Exception('Item not found');

      final int oldStock = item.jumlahBarang;
      final int newStock = type == 'Add Stock'
          ? oldStock + change
          : type == 'Remove Stock'
              ? oldStock - change
              : change; // Correction sets it directly

      final int actualChange = newStock - oldStock;
      item.jumlahBarang = newStock;
      await isar.itemModels.put(item);

      final detailsMap = {
        'productName': item.nama,
        'change': actualChange,
        'oldStock': oldStock,
        'newStock': newStock,
        'reason': reason,
        'type': type,
      };

      final audit = AuditModel(
        action: 'STOCK_ADJUSTMENT',
        details: jsonEncode(detailsMap),
        createdAt: DateTime.now(),
      );
      await isar.auditModels.put(audit);
    });
  }

  insertInventoryFresh(List<ItemModel> inventoryList) async {
    final isar = await db;
    await clearInventory();
    if (inventoryList.isNotEmpty) {
      await Future.forEach(
          inventoryList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.itemModels.put(val)));
    }
  }

  Future<List<ItemModel>> searchInventorys({String? value}) async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    final items = inventoryCollection
        .filter()
        .group((q) => q
            .namaContains(value ?? '', caseSensitive: false)
            .or()
            .codeContains(value ?? '', caseSensitive: false))
        .findAll();
    return items;
  }

  Future<ItemModel?> searchByBarcode(String value) async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    final items = await inventoryCollection
        .filter()
        .group((q) => q.codeContains(value, caseSensitive: false))
        .findFirst();
    return items;
  }

  void updateInventorySync(ItemModel inventory) async {
    final isar = await db;
    inventory.isSynced = true;
    await isar.writeTxn(() async {
      await isar.itemModels.put(inventory);
    });
  }

  getUnsyncedInventoryData() async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    List<ItemModel?> items =
        await inventoryCollection.filter().isSyncedEqualTo(false).findAll();
    return items;
  }

  Future<void> checkIsInventorySynced() async {
    final inventorys = await searchInventorys();
    if (inventorys.isNotEmpty) {
      List<ItemModel> unsyncedInventory = await getUnsyncedInventoryData();
      if (inventoryController.deleteItemList.value.isNotEmpty) {
        await Future.forEach(inventoryController.deleteItemList.value,
            (element) async => _supabaseHelper.removeInventory(element.id!));
        // for (ItemModel element in inventoryController.deleteItemList.value) {
        //   _supabaseHelper.removeInventory(element.id!);
        // }
        inventoryController.deleteItemList.value.clear();
      }
      if (unsyncedInventory.isNotEmpty) {
        await Future.forEach(unsyncedInventory, (element) async {
          element.isSynced = true;
          await _supabaseHelper.updateInventory(element);
          updateInventorySync(element);
        });
      }
      // refresh
      final res = await _supabaseHelper.getInventoryAll();
      await insertInventoryFresh(res);
    } else {
      final res = await _supabaseHelper.getInventoryAll();
      await insertInventoryFresh(res);
      getInventorys();
    }
  }

  Future<void> clearInventory() async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    isar.writeTxn<void>(() => inventoryCollection.clear());
  }

  Future<List<ItemModel>> getOutStock() async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    final items = inventoryCollection
        .filter()
        .group((q) => q.jumlahBarangLessThan(1))
        .findAll();
    return items;
  }

  Future<List<ItemModel>> getLowStock({int threshold = 5}) async {
    final isar = await db;
    IsarCollection<ItemModel> inventoryCollection =
        isar.collection<ItemModel>();
    final items = await inventoryCollection.where().findAll();
    return items
        .where((item) => item.jumlahBarang <= (item.lowStockLimit ?? threshold))
        .toList();
  }

  // sales
  Future<void> addPenjualan(PenjualanModel val) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final id = await isar.penjualanModels.put(val);
      final prefix = DateFormat('ddMMyyHHmm').format(val.createdAt);
      val.billNumber = prefix + id.toString().padLeft(3, '0');
      await isar.penjualanModels.put(val);
    });
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addReport(val.toJson());
    }
  }

  Future<void> syncItemPenjualan(PenjualanModel val) async {
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addReport(val.toJson());
    }
  }

  Future<void> removePenjualan(int val) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final existing = await isar.penjualanModels.get(val);
      if (existing != null) {
        for (var element in existing.items) {
          if (element.id != null) {
            final catalogItem = await isar.itemModels.get(element.id!);
            if (catalogItem != null) {
              catalogItem.jumlahBarang += element.quantity ?? 0;
              await isar.itemModels.put(catalogItem);
            }
          }
        }
        
        final audit = AuditModel(
          action: existing.printed ? 'DELETE_BILL' : 'PENDING_BILL_DELETED',
          billNumber: existing.billNumber,
          customerName: existing.customerName,
          amount: existing.totalHarga,
          details: 'Restored inventory for ${existing.items.length} items',
        );
        await isar.auditModels.put(audit);
      }
      await isar.penjualanModels.delete(val);
    });
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeReport(val);
    }
  }

  Future<int> getPendingPrintsCount() async {
    final isar = await db;
    return await isar.penjualanModels.filter().printedEqualTo(false).count();
  }

  Future<void> clearReport() async {
    final isar = await db;
    IsarCollection<PenjualanModel> reportCollection =
        isar.collection<PenjualanModel>();
    isar.writeTxn<void>(() => reportCollection.clear());
  }

  insertReportFresh(List<PenjualanModel> reportList) async {
    final isar = await db;
    await clearReport();

    if (reportList.isNotEmpty) {
      await Future.forEach(
          reportList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.penjualanModels.put(val)));
    }
  }

  Future<List<PenjualanModel>> getReport(
      {required DateTime start, required DateTime end}) async {
    final isar = await db;
    IsarCollection<PenjualanModel> reportCollection =
        isar.collection<PenjualanModel>();
    final items = await reportCollection
        .where()
        .filter()
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
    return items;
  }

  Future<List<PenjualanModel>> getReportById({
    required DateTime start,
    required DateTime end,
    int? userId,
  }) async {
    final isar = await db;
    IsarCollection<PenjualanModel> reportCollection =
        isar.collection<PenjualanModel>();

    final items = await reportCollection
        .where()
        .filter()
        .createdAtBetween(
          start.copyWith(hour: 0, minute: 0, second: 0),
          end.copyWith(hour: 23, minute: 59, second: 59),
        )
        .kasirEqualTo(userId ?? 0)
        .findAll();

    return items;
  }

  Future<List<PenjualanModel>> getReportToday() async {
    final isar = await db;
    IsarCollection<PenjualanModel> inventoryCollection =
        isar.collection<PenjualanModel>();
    final items = await inventoryCollection
        .filter()
        .createdAtBetween(
            DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
            DateTime.now().copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
    return items;
  }

  Future<List<PenjualanModel>> getReportYesterday() async {
    final isar = await db;
    IsarCollection<PenjualanModel> inventoryCollection =
        isar.collection<PenjualanModel>();
    final items = await inventoryCollection
        .filter()
        .createdAtBetween(
            DateTime.now()
                .subtract(const Duration(days: 1))
                .copyWith(hour: 0, minute: 0, second: 0),
            DateTime.now()
                .subtract(const Duration(days: 1))
                .copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
    return items;
  }

  Future<Map<int, List<PenjualanModel>>> getSalesByUser() async {
    final isar = await db;
    IsarCollection<PenjualanModel> inventoryCollection =
        isar.collection<PenjualanModel>();
    final items = await inventoryCollection.where().findAll();

    final Map<int, List<PenjualanModel>> listOfOrders =
        items.groupListsBy((i) => i.kasir);

    return listOfOrders;
  }

  Future<Map<DateTime, List<PenjualanModel>>> getSalesByDate(
      {required DateTime start, required DateTime end}) async {
    final isar = await db;
    IsarCollection<PenjualanModel> inventoryCollection =
        isar.collection<PenjualanModel>();
    List<PenjualanModel> items = inventoryCollection
        .where()
        .filter()
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .findAllSync();

    final Map<DateTime, List<PenjualanModel>> listOfOrders = items.groupListsBy(
        (order) => DateTime(
            order.createdAt.year, order.createdAt.month, order.createdAt.day));

    return listOfOrders;
  }

  Future<List<PenjualanModel>> getReportAll() async {
    final isar = await db;
    IsarCollection<PenjualanModel> reportCollection =
        isar.collection<PenjualanModel>();
    return await reportCollection.where().findAll();
  }

  Future<void> checkIsReportSynced() async {
    final reports = await getReportAll();
    if (reports.isNotEmpty) {
      for (PenjualanModel element in reports) {
        final res = await _supabaseHelper.getReportById(element.id!);
        if (res == false) {
          _supabaseHelper.addReport(element.toJson());
        }
      }
    } else {
      getReportAll();
    }
  }

  Future<void> addStore(StoreModel val) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.storeModels.putSync(val));
    await SecureStorageHelper.saveStoreSettings(
      title: val.title,
      description: val.description,
      phone: val.phone,
      footer: val.footer,
      subFooter: val.subFooter,
      logoPath: val.logoPath,
      currencySymbol: val.currencySymbol,
      paperSize: val.paperSize,
      backupFolderPath: val.backupFolderPath,
    );
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateStore(val);
    }
  }

  Future<StoreModel?> getStore() async {
    final isar = await db;
    IsarCollection<StoreModel> storeCollection = isar.collection<StoreModel>();
    StoreModel? store = await storeCollection.where().findFirst();
    if (store == null) {
      final settings = await SecureStorageHelper.getStoreSettings();
      if (settings['title'] != 'Wajahat POS' || settings['phone']!.isNotEmpty) {
        store = StoreModel(
          title: settings['title']!,
          description: settings['description']!,
          phone: settings['phone']!,
          footer: settings['footer'],
          subFooter: settings['subFooter'],
          logoPath: settings['logoPath'],
          currencySymbol: settings['currencySymbol'],
          paperSize: settings['paperSize'],
          backupFolderPath: settings['backupFolderPath'],
        );
        isar.writeTxnSync<int>(() => isar.storeModels.putSync(store!));
      }
    }
    return store;
  }

  Future<void> syncStore() async {
    final store = await getStore();
    if (store != null) {
      _supabaseHelper.updateStore(store);
    } else {
      final res = await _supabaseHelper.getStore();
      if (res != null) {
        await addStore(res);
      }
    }
  }

  // presense
  Future<void> addPresense(PresenceModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.presenceModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addPresense(val.toJson());
    }
  }

  Future<List<PresenceModel>> getPresense(
      {required DateTime start, required DateTime end}) async {
    final isar = await db;
    IsarCollection<PresenceModel> presenseCollection =
        isar.collection<PresenceModel>();
    return await presenseCollection
        .where()
        .filter()
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
  }

  // sync presense
  Future<void> presenseSync() async {
    final isar = await db;
    IsarCollection<PresenceModel> presenseCollection =
        isar.collection<PresenceModel>();

    final presense = await presenseCollection.where().findAll();
    if (presense.isNotEmpty) {
      final res = await _supabaseHelper.getPresense();
      if (res.length != presense.length) {
        if (presense.length >= res.length) {
          await Future.forEach(presense, (val) async {
            final res = await _supabaseHelper.getPresenseById(val.id!);
            if (res == false) {
              _supabaseHelper.addPresense(val.toJson());
            }
          });
          final res = await _supabaseHelper.getPresense();
          await insertPresenseFresh(res);
        } else {
          await insertPresenseFresh(res);
        }
      }
    } else {
      final res = await _supabaseHelper.getPresense();
      await insertPresenseFresh(res);
    }
  }

  Future<void> clearPresense() async {
    final isar = await db;
    IsarCollection<PresenceModel> presenseCollection =
        isar.collection<PresenceModel>();
    isar.writeTxn<void>(() => presenseCollection.clear());
  }

  insertPresenseFresh(List<PresenceModel> presenseList) async {
    final isar = await db;
    await clearPresense();

    if (presenseList.isNotEmpty) {
      await Future.forEach(
          presenseList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.presenceModels.put(val)));
    }
  }

  // rent item
  Future<void> addRentItem(RentItemModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.rentItemModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addRentItem(val.toJson());
    }
  }

  Future<List<RentItemModel>> getRentItem() async {
    final isar = await db;
    IsarCollection<RentItemModel> rentItemCollection =
        isar.collection<RentItemModel>();

    return await rentItemCollection.where().findAll();
  }

  Future<RentItemModel?> getRentItemById(int id) async {
    final isar = await db;
    IsarCollection<RentItemModel> rentItemCollection =
        isar.collection<RentItemModel>();
    final rent = rentItemCollection.get(id);
    return rent;
  }

  Future<void> deleteRentItem(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.rentItemModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeRentItem(val);
    }
  }

  Future<void> updateRentItem(RentItemModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() async => await isar.rentItemModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateRentItem(val);
    }
  }

  // sync rent items
  Future<void> rentItemSync() async {
    final rentItems = await getRentItem();
    if (rentItems.isNotEmpty) {
      final res = await _supabaseHelper.getRentItems();
      if (res.length != rentItems.length) {
        if (rentItems.length >= res.length) {
          await Future.forEach(rentItems, (val) async {
            final res = await _supabaseHelper.getRentItemById(val.id!);
            if (res == false) {
              _supabaseHelper.addRentItem(val.toJson());
            }
          });
          final res = await _supabaseHelper.getRentItems();
          await insertRentItemsFresh(res);
        } else {
          await insertRentItemsFresh(res);
        }
      }
    } else {
      final res = await _supabaseHelper.getRentItems();
      await insertRentItemsFresh(res);
    }
  }

  Future<void> clearRentItems() async {
    final isar = await db;
    IsarCollection<RentItemModel> rentItemsCollection =
        isar.collection<RentItemModel>();
    isar.writeTxn<void>(() => rentItemsCollection.clear());
  }

  insertRentItemsFresh(List<RentItemModel> rentItemList) async {
    final isar = await db;
    await clearRentItems();
    if (rentItemList.isNotEmpty) {
      await Future.forEach(
          rentItemList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.rentItemModels.put(val)));
    }
  }

  // rent
  Future<void> addRent(RentModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.rentModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addRent(val.toJson());
    }
  }

  Future<List<RentModel>> getRent() async {
    final isar = await db;
    IsarCollection<RentModel> rentCollection = isar.collection<RentModel>();
    return await rentCollection.where().findAll();
  }

  Future<void> updateRent(RentModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() async => await isar.rentModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateRent(val);
    }
  }

  Future<List<RentModel>> getRentRevenue() async {
    final isar = await db;
    IsarCollection<RentModel> rentCollection = isar.collection<RentModel>();

    return await rentCollection.filter().paidEqualTo(true).findAll();
  }

  // sync rent
  Future<void> rentSync() async {
    final rent = await getRent();
    if (rent.isNotEmpty) {
      final res = await _supabaseHelper.getRent();
      if (res.length != rent.length) {
        if (rent.length >= res.length) {
          await Future.forEach(rent, (val) async {
            final res = await _supabaseHelper.getRentById(val.id!);
            if (res == false) {
              _supabaseHelper.addRent(val.toJson());
            }
          });
          final res = await _supabaseHelper.getRent();
          await insertRentFresh(res);
        } else {
          await insertRentFresh(res);
        }
      }
    } else {
      final res = await _supabaseHelper.getRent();
      await insertRentFresh(res);
    }
  }

  Future<void> clearRent() async {
    final isar = await db;
    IsarCollection<RentModel> rentCollection = isar.collection<RentModel>();
    isar.writeTxn<void>(() => rentCollection.clear());
  }

  insertRentFresh(List<RentModel> rentList) async {
    final isar = await db;
    await clearRent();
    if (rentList.isNotEmpty) {
      await Future.forEach(
          rentList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.rentModels.put(val)));
    }
  }

  // expenses
  Future<void> addExpenses(ExpensesModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.expensesModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addExpenses(val.toJson());
    }
  }

  Future<void> deleteExpenses(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.expensesModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeExpenses(val);
    }
  }

  Future<List<ExpensesModel>> getExpenses(
      {required DateTime start, required DateTime end}) async {
    final isar = await db;
    IsarCollection<ExpensesModel> expensesCollection =
        isar.collection<ExpensesModel>();
    return await expensesCollection
        .where()
        .filter()
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .findAll();
  }

  // sync expenses
  Future<void> expensesSync() async {
    final isar = await db;
    IsarCollection<ExpensesModel> expensesCollection =
        isar.collection<ExpensesModel>();

    final expenses = await expensesCollection.where().findAll();
    if (expenses.isNotEmpty) {
      final res = await _supabaseHelper.getExpenses();
      if (res.length != expenses.length) {
        if (expenses.length >= res.length) {
          await Future.forEach(expenses, (val) async {
            final res = await _supabaseHelper.getRentById(val.id!);
            if (res == false) {
              _supabaseHelper.addExpenses(val.toJson());
            }
          });
          final res = await _supabaseHelper.getExpenses();
          insertExpensesFresh(res);
        } else {
          insertExpensesFresh(res);
        }
      }
    } else {
      final res = await _supabaseHelper.getExpenses();
      insertExpensesFresh(res);
    }
  }

  Future<void> clearExpenses() async {
    final isar = await db;
    IsarCollection<ExpensesModel> expensesCollection =
        isar.collection<ExpensesModel>();
    isar.writeTxn<void>(() => expensesCollection.clear());
  }

  insertExpensesFresh(List<ExpensesModel> expensesList) async {
    final isar = await db;
    await clearExpenses();

    if (expensesList.isNotEmpty) {
      await Future.forEach(
          expensesList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.expensesModels.put(val)));
    }
  }

  // Salary
  Future<void> addSalary(SalaryModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.salaryModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addSalary(val.toJson());
    }
  }

  Future<List<SalaryModel>> getSalary() async {
    final isar = await db;
    IsarCollection<SalaryModel> salaryCollection =
        isar.collection<SalaryModel>();

    return await salaryCollection.where().findAll();
  }

  Future<void> updateSalary(SalaryModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() async => await isar.salaryModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateSalary(val);
    }
  }

  Future<void> deleteSalary(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.salaryModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeSalary(val);
    }
  }

  // sync salaries
  Future<void> salariesSync() async {
    final isar = await db;
    IsarCollection<SalaryModel> salaryCollection =
        isar.collection<SalaryModel>();

    final salary = await salaryCollection.where().findAll();
    if (salary.isNotEmpty) {
      final res = await _supabaseHelper.getSalarys();
      if (res.length != salary.length) {
        if (salary.length >= res.length) {
          await Future.forEach(salary, (val) async {
            final res = await _supabaseHelper.getSalariesById(val.id!);
            if (res == false) {
              _supabaseHelper.addSalary(val.toJson());
            }
          });
          final res = await _supabaseHelper.getSalarys();
          await insertSalaryFresh(res);
        } else {
          await insertSalaryFresh(res);
        }
      }
    } else {
      final res = await _supabaseHelper.getSalarys();
      await insertSalaryFresh(res);
    }
  }

  Future<void> clearSalary() async {
    final isar = await db;
    IsarCollection<SalaryModel> salaryCollection =
        isar.collection<SalaryModel>();
    isar.writeTxn<void>(() => salaryCollection.clear());
  }

  insertSalaryFresh(List<SalaryModel> salaryList) async {
    final isar = await db;
    await clearSalary();

    if (salaryList.isNotEmpty) {
      await Future.forEach(
          salaryList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.salaryModels.put(val)));
    }
  }

  // due payment
  // inventory
  Future<void> addDuePayment(DuePaymentModel val) async {
    val.isSynced = isDeviceConnected.value && supabase.auth.currentUser != null;
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.duePaymentModels.putSync(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.addDuePayment(val.toJson());
    }
  }

  Future<void> deleteDuePayment(int val) async {
    final isar = await db;
    isar.writeTxn<bool>(() async => await isar.duePaymentModels.delete(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.removeDuePayment(val);
    }
  }

  Future<void> updateDuePayment(DuePaymentModel val) async {
    final isar = await db;
    isar.writeTxn<int>(() async => await isar.duePaymentModels.put(val));
    if (isDeviceConnected.value && supabase.auth.currentUser != null) {
      _supabaseHelper.updateDuePayment(val);
    }
  }

  Future<List<DuePaymentModel>> getDuePayments({String? value}) async {
    final isar = await db;
    IsarCollection<DuePaymentModel> duePaymentCollection =
        isar.collection<DuePaymentModel>();
    return await duePaymentCollection.where().findAll();
  }

  // sync due payment
  Future<void> duePaymentSync() async {
    final duePayments = await getDuePayments();
    if (duePayments.isNotEmpty) {
      final res = await _supabaseHelper.getDuePayment();
      if (res.length != duePayments.length) {
        if (duePayments.length >= res.length) {
          await Future.forEach(duePayments, (val) async {
            final res = await _supabaseHelper.getDuePaymentById(val.id!);
            if (res == false) {
              _supabaseHelper.addDuePayment(val.toJson());
            }
          });
          final res = await _supabaseHelper.getDuePayment();
          await insertDuePaymentFresh(res);
        } else {
          await insertDuePaymentFresh(res);
        }
      }
    } else {
      final res = await _supabaseHelper.getDuePayment();
      await insertDuePaymentFresh(res);
    }
  }

  Future<void> clearDuePayment() async {
    final isar = await db;
    IsarCollection<DuePaymentModel> duePaymentCollection =
        isar.collection<DuePaymentModel>();
    isar.writeTxn<void>(() => duePaymentCollection.clear());
  }

  insertDuePaymentFresh(List<DuePaymentModel> duePaymentList) async {
    final isar = await db;
    await clearDuePayment();
    if (duePaymentList.isNotEmpty) {
      await Future.forEach(
          duePaymentList,
          (val) async =>
              await isar.writeTxn<int>(() => isar.duePaymentModels.put(val)));
    }
  }

  Future<String> createBackUp() async {
    final isar = await db;
    final store = await getStore();
    String backUpPath = '';
    
    final docDir = await getApplicationDocumentsDirectory();
    final rootPath = p.join(docDir.path, 'Wajahat');
    if (store != null && store.backupFolderPath != null && store.backupFolderPath!.isNotEmpty) {
      backUpPath = store.backupFolderPath!;
      final dir = Directory(backUpPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      backUpPath = p.join(rootPath, 'backups');
    }

    if (backUpPath.isEmpty) {
      await isar.writeTxn(() async {
        await isar.auditModels.put(AuditModel(action: 'BACKUP_FAILED', details: 'Backup path is invalid or empty.'));
      });
      throw Exception("Backup path is not valid");
    }

    final String timestamp = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
    final String zipFileName = 'backup_$timestamp.zip';
    final String zipFullPath = p.join(backUpPath, zipFileName);

    final tempDir = await getTemporaryDirectory();
    final String tempIsarPath = p.join(tempDir.path, 'temp_backup_$timestamp.isar');

    try {
      // 1. Copy database file to a temporary file
      await isar.copyToFile(tempIsarPath);

      // 2. Zip the temporary isar file and the images folder
      final encoder = ZipFileEncoder();
      encoder.create(zipFullPath);
      encoder.addFile(File(tempIsarPath), 'default.isar');

      final imagesDir = Directory(p.join(rootPath, 'images'));
      if (await imagesDir.exists()) {
        await for (final file in imagesDir.list(recursive: true)) {
          if (file is File) {
            final String relativePath = 'images/${p.basename(file.path)}';
            encoder.addFile(file, relativePath);
          }
        }
      }

      if (store != null && store.logoPath != null && store.logoPath!.isNotEmpty) {
        final logoFile = File(store.logoPath!);
        if (await logoFile.exists()) {
          // Add logo to the zip in a logos/ directory
          final String relativePath = 'logos/${p.basename(store.logoPath!)}';
          encoder.addFile(logoFile, relativePath);
        }
      }
      
      encoder.close();

      // 3. Delete temporary isar file
      final tempFile = File(tempIsarPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await isar.writeTxn(() async {
        await isar.auditModels.put(AuditModel(action: 'DATABASE_BACKUP', details: 'Exported database and images to $zipFullPath'));
      });
    } catch (e) {
      await isar.writeTxn(() async {
        await isar.auditModels.put(AuditModel(action: 'BACKUP_FAILED', details: e.toString()));
      });
      rethrow;
    }
    return zipFullPath;
  }

  Future<void> restoreDB(String backupFilePath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final rootPath = p.join(docDir.path, 'Wajahat');
    final dbDirectory = Directory(p.join(rootPath, 'database'));
    final isar = await db;
    final tempDir = await getTemporaryDirectory();

    bool isZip = backupFilePath.endsWith('.zip');
    String isarToRestorePath = backupFilePath;

    if (isZip) {
      // 1. Extract database from Zip to temp path to perform integrity check
      final bytes = await File(backupFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final isarFile = archive.findFile('default.isar');
      if (isarFile == null) {
        throw Exception('Backup zip file does not contain default.isar');
      }
      final tempPath = p.join(tempDir.path, 'temp_restore_check.isar');
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await tempFile.writeAsBytes(isarFile.content as List<int>);
      isarToRestorePath = tempPath;
    }

    // Perform integrity check on isarToRestorePath
    final integrityIsarPath = p.join(tempDir.path, 'temp_integrity_check.isar');
    final integrityFile = File(integrityIsarPath);
    if (await integrityFile.exists()) {
      await integrityFile.delete();
    }
    await File(isarToRestorePath).copy(integrityIsarPath);

    try {
      final tempIsar = await Isar.open(
        [
          ItemModelSchema,
          CustomerModelSchema,
          PenjualanModelSchema,
          UserModelSchema,
          AuthModelSchema,
          StoreModelSchema,
          PresenceModelSchema,
          RentItemModelSchema,
          RentModelSchema,
          ExpensesModelSchema,
          SalaryModelSchema,
          DuePaymentModelSchema,
          AuditModelSchema
        ],
        directory: tempDir.path,
        name: 'temp_integrity_check',
      );
      await tempIsar.close();
      if (await integrityFile.exists()) await integrityFile.delete();
    } catch (e) {
      await isar.writeTxn(() async {
        await isar.auditModels.put(AuditModel(action: 'RESTORE_FAILED', details: 'Integrity check failed: $e'));
      });
      throw Exception("Invalid backup file: Database integrity check failed. $e");
    }

    // 2. Create emergency backup (zip style)
    final store = await getStore();
    String backUpPath = '';
    if (store != null && store.backupFolderPath != null && store.backupFolderPath!.isNotEmpty) {
      backUpPath = store.backupFolderPath!;
      final dir = Directory(backUpPath);
      if (!await dir.exists()) await dir.create(recursive: true);
    } else {
      backUpPath = p.join(rootPath, 'backups');
    }
    if (backUpPath.isNotEmpty) {
      final String timestamp = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
      final String emergencyZipPath = p.join(backUpPath, 'pre_restore_backup_$timestamp.zip');
      try {
        final tempEmergencyIsarPath = p.join(tempDir.path, 'temp_emergency_$timestamp.isar');
        await isar.copyToFile(tempEmergencyIsarPath);
        final encoder = ZipFileEncoder();
        encoder.create(emergencyZipPath);
        encoder.addFile(File(tempEmergencyIsarPath), 'default.isar');
        final imagesDir = Directory(p.join(rootPath, 'images'));
        if (await imagesDir.exists()) {
          await for (final file in imagesDir.list(recursive: true)) {
            if (file is File) {
              encoder.addFile(file, 'images/${p.basename(file.path)}');
            }
          }
        }
        encoder.close();
        final tempEmergencyFile = File(tempEmergencyIsarPath);
        if (await tempEmergencyFile.exists()) await tempEmergencyFile.delete();
      } catch (e) {
        print('Emergency backup failed: $e');
      }
    }

    // 3. Log restore event (audit log)
    await isar.writeTxn(() async {
      await isar.auditModels.put(AuditModel(action: 'DATABASE_RESTORE', details: 'Restoring from $backupFilePath'));
    });
    final logFile = File(p.join(rootPath, 'logs', 'restore_audit.log'));
    await logFile.writeAsString(
      'RESTORE EVENT: ${DateTime.now().toIso8601String()} | Source File: $backupFilePath\n',
      mode: FileMode.append,
    );

    // 4. Close Isar safely
    await isar.close(deleteFromDisk: true);

    // 5. Replace database and extract images if Zip
    if (isZip) {
      final bytes = await File(backupFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          String outPath;
          if (file.name == 'default.isar') {
            outPath = p.join(rootPath, 'database', 'default.isar');
          } else {
            outPath = p.join(rootPath, file.name);
          }
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
      }
      // Clean up temp file
      final tempRestoredIsar = File(isarToRestorePath);
      if (await tempRestoredIsar.exists()) {
        await tempRestoredIsar.delete();
      }

      // Update store logo path if a logo was extracted
      final logosDir = Directory(p.join(rootPath, 'logos'));
      if (await logosDir.exists()) {
        final logoFiles = logosDir.listSync();
        if (logoFiles.isNotEmpty) {
          final isarRestore = await openDB();
          final storeModel = await isarRestore.storeModels.where().findFirst();
          if (storeModel != null) {
            await isarRestore.writeTxn(() async {
              storeModel.logoPath = logoFiles.first.path;
              await isarRestore.storeModels.put(storeModel);
            });
          }
          await isarRestore.close();
        }
      }
    } else {
      // Normal .isar restore (fallback for older backup formats)
      await File(backupFilePath).copy(p.join(rootPath, 'database', 'default.isar'));
    }

    // 6. Force application restart
    await Process.start(Platform.resolvedExecutable, Platform.executableArguments);
    exit(0);
  }

  Future<void> factoryReset() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.auditModels.put(AuditModel(action: 'SYSTEM_RESET', details: 'Factory Reset executed.'));
    });
    await isar.writeTxn<void>(() => isar.clear());
    await isar.close(deleteFromDisk: true);
    await Process.start(Platform.resolvedExecutable, Platform.executableArguments);
    exit(0);
  }

  Future<void> clearBusinessData() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.itemModels.clear();
      await isar.penjualanModels.clear();
      // We clear audit models but add one entry for the clear event.
      await isar.auditModels.clear();
      await isar.auditModels.put(AuditModel(action: 'BUSINESS_DATA_CLEARED', details: 'All business data cleared. Settings retained.'));
    });
  }

  Future<void> ensureWajahatStructure() async {
    if (_structureEnsured) return;
    _structureEnsured = true;
    final docDir = await getApplicationDocumentsDirectory();
    final rootPath = p.join(docDir.path, 'Wajahat');
    final folders = ['database', 'backups', 'exports', 'images', 'logos', 'logs', 'receipts'];
    for (final folder in folders) {
      final dir = Directory(p.join(rootPath, folder));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }

    // Migration Logic:
    // If old database exists in Documents/default.isar, move it to Documents/Wajahat/database/default.isar
    final oldDbFile = File(p.join(docDir.path, 'default.isar'));
    final newDbFile = File(p.join(rootPath, 'database', 'default.isar'));
    if (await oldDbFile.exists() && !await newDbFile.exists()) {
      try {
        await oldDbFile.copy(newDbFile.path);
        await oldDbFile.delete();
      } catch (e) {
        print('Error migrating database: $e');
      }
    }

    // Move old images if exists in Documents/images/
    final oldImagesDir = Directory(p.join(docDir.path, 'images'));
    final newImagesDir = Directory(p.join(rootPath, 'images'));
    if (await oldImagesDir.exists()) {
      try {
        await for (final file in oldImagesDir.list(recursive: true)) {
          if (file is File) {
            final destFile = File(p.join(newImagesDir.path, p.basename(file.path)));
            await file.copy(destFile.path);
            await file.delete();
          }
        }
        await oldImagesDir.delete(recursive: true);
      } catch (e) {
        print('Error migrating images: $e');
      }
    }

    // Move old restore_audit.log if exists in Documents/restore_audit.log
    final oldLogFile = File(p.join(docDir.path, 'restore_audit.log'));
    final newLogFile = File(p.join(rootPath, 'logs', 'restore_audit.log'));
    if (await oldLogFile.exists() && !await newLogFile.exists()) {
      try {
        await oldLogFile.copy(newLogFile.path);
        await oldLogFile.delete();
      } catch (e) {
        print('Error migrating log file: $e');
      }
    }
  }

  Future<Isar> openDB() async {
    await ensureWajahatStructure();
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'Wajahat', 'database');
      final isar = await Isar.open(
        [
          ItemModelSchema,
          CustomerModelSchema,
          PenjualanModelSchema,
          UserModelSchema,
          AuthModelSchema,
          StoreModelSchema,
          PresenceModelSchema,
          RentItemModelSchema,
          RentModelSchema,
          ExpensesModelSchema,
          SalaryModelSchema,
          DuePaymentModelSchema,
          AuditModelSchema
        ],
        directory: dbPath,
        inspector: true,
      );

      return isar;
    }

    return Future.value(Isar.getInstance());
  }
}
