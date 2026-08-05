import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/utils/pdf_service.dart';
import 'package:due_kasir/utils/csv_service.dart';
import 'package:isar/isar.dart';
import 'package:archive/archive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async => 'C:/project/duekasir/.dart_tool/test_db/docs';
  @override
  Future<String?> getDownloadsPath() async => 'C:/project/duekasir/.dart_tool/test_db/downloads';
  @override
  Future<String?> getTemporaryPath() async => 'C:/project/duekasir/.dart_tool/test_db/temp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String docsPath = 'C:/project/duekasir/.dart_tool/test_db/docs';
  const String downloadsPath = 'C:/project/duekasir/.dart_tool/test_db/downloads';
  const String tempPath = 'C:/project/duekasir/.dart_tool/test_db/temp';

  setUpAll(() async {
    // Clean directory
    final dir = Directory('C:/project/duekasir/.dart_tool/test_db');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await Directory(docsPath).create(recursive: true);
    await Directory(downloadsPath).create(recursive: true);
    await Directory(tempPath).create(recursive: true);

    // Override PathProvider Platform
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Initialize Isar native binaries for unit tests
    await Isar.initializeIsarCore(download: false);
  });

  test('POS Phase 6 Complete Workflow Integration Test', () async {
    final dbHelper = Database();
    final isar = await dbHelper.db;

    // Initialize Store Info
    final store = StoreModel(
      title: 'Headless Test Shop',
      description: '123 Test Street',
      phone: '0000000000',
      footer: 'Thank you for shopping!',
      paperSize: '58 mm',
      backupFolderPath: 'C:/project/duekasir/.dart_tool/test_db/backups',
    );
    await isar.writeTxn(() => isar.storeModels.put(store));

    // 1. Inventory Test
    // Create Apple
    final apple = ItemModel(
      nama: 'Apple',
      code: 'APL',
      jumlahBarang: 100,
      quantity: 0,
      hargaDasar: 50,
      hargaJual: 100,
      lowStockLimit: 10,
    );
    
    await isar.writeTxn(() => isar.itemModels.put(apple));
    
    // Verify Add works
    var fetchedApple = await isar.itemModels.where().filter().namaEqualTo('Apple').findFirst();
    expect(fetchedApple, isNotNull);
    expect(fetchedApple!.jumlahBarang, 100);

    // Edit works
    fetchedApple.jumlahBarang = 100; // keeping stock 100
    await isar.writeTxn(() => isar.itemModels.put(fetchedApple!));
    fetchedApple = await isar.itemModels.where().filter().namaEqualTo('Apple').findFirst();
    expect(fetchedApple!.jumlahBarang, 100);

    // Search works
    final searchResult = await isar.itemModels.where().filter().namaContains('App').findAll();
    expect(searchResult.length, 1);

    // 2. Sale Test
    // Sell 10 Apples
    final penjualanItem = ProductItemModel(
      id: fetchedApple.id,
      nama: fetchedApple.nama,
      code: fetchedApple.code,
      jumlahBarang: fetchedApple.jumlahBarang,
      quantity: 10,
      hargaJual: fetchedApple.hargaJual,
      hargaDasar: fetchedApple.hargaDasar,
      isSynced: true,
    );

    // Fetch next sequential bill number
    final count = await isar.penjualanModels.count();
    final billNumber = (count + 1).toString().padLeft(6, '0');

    final bill = PenjualanModel(
      billNumber: billNumber,
      customerName: 'Ali',
      items: [penjualanItem],
      totalItem: 10,
      totalHarga: 1000,
      kasir: 1,
      createdAt: DateTime.now(),
    );

    await isar.writeTxn(() async {
      await isar.penjualanModels.put(bill);
      // Reduce inventory
      fetchedApple!.jumlahBarang -= 10;
      await isar.itemModels.put(fetchedApple);
    });

    // Verify stock becomes 90
    var updatedApple = await isar.itemModels.get(fetchedApple.id!);
    expect(updatedApple!.jumlahBarang, 90);

    // Verify Bill created and bill number matches
    final fetchedBill = await isar.penjualanModels.where().filter().billNumberEqualTo('000001').findFirst();
    expect(fetchedBill, isNotNull);
    expect(fetchedBill!.customerName, 'Ali');

    // 3. Profit Test
    expect(fetchedBill.totalHarga, 1000);
    final revenue = fetchedBill.totalHarga;
    double cost = 0;
    for (var item in fetchedBill.items) {
      cost += (item.hargaDasar ?? 0) * (item.quantity ?? 0);
    }
    final profit = revenue - cost;
    expect(revenue, 1000);
    expect(profit, 500);

    // 4. Delete Bill Test
    await isar.writeTxn(() async {
      // Revert inventory
      for (var element in fetchedBill.items) {
        if (element.id != null) {
          final catalogItem = await isar.itemModels.get(element.id!);
          if (catalogItem != null) {
            catalogItem.jumlahBarang += element.quantity ?? 0;
            await isar.itemModels.put(catalogItem);
          }
        }
      }
      
      // Audit log creation
      final audit = AuditModel(
        action: 'DELETE_BILL',
        billNumber: fetchedBill.billNumber,
        customerName: fetchedBill.customerName,
        amount: fetchedBill.totalHarga,
        details: 'Restored inventory for ${fetchedBill.items.length} items',
      );
      await isar.auditModels.put(audit);
      await isar.penjualanModels.delete(fetchedBill.id!);
    });

    // Verify stock returns to 100
    final revertedApple = await isar.itemModels.get(fetchedApple.id!);
    expect(revertedApple!.jumlahBarang, 100);

    // Verify Audit Log was created
    final deleteAudit = await isar.auditModels.where().filter().actionEqualTo('DELETE_BILL').findFirst();
    expect(deleteAudit, isNotNull);
    expect(deleteAudit!.billNumber, '000001');

    // Verify profit disappears (bill deleted)
    final remainingBills = await isar.penjualanModels.where().findAll();
    expect(remainingBills.isEmpty, true);

    // Re-create the sale bill for PDF and CSV testing
    await isar.writeTxn(() async {
      await isar.penjualanModels.put(bill);
      revertedApple.jumlahBarang -= 10;
      await isar.itemModels.put(revertedApple);
    });

    // 5. Backup Test
    final backupPath = await dbHelper.createBackUp();
    expect(File(backupPath).existsSync(), true);

    // 6. Restore Test
    // Add fake product
    final fakeItem = ItemModel(
      nama: 'FakeSoda',
      code: 'SDA',
      jumlahBarang: 5,
      quantity: 0,
      hargaDasar: 10,
      hargaJual: 20,
    );
    await isar.writeTxn(() => isar.itemModels.put(fakeItem));
    expect((await isar.itemModels.where().filter().namaEqualTo('FakeSoda').findFirst()), isNotNull);

    // Manual DB Restore validation (Close, Swap file, Open)
    await isar.close();
    
    // Extract default.isar from backup zip over activeDbFile
    final bytes = await File(backupPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final isarFile = archive.findFile('default.isar');
    expect(isarFile, isNotNull);
    final activeDbFile = File('$docsPath/Wajahat/database/default.isar');
    await activeDbFile.writeAsBytes(isarFile!.content as List<int>);

    // Reopen database
    final reopenedIsar = await dbHelper.openDB();
    expect(reopenedIsar.isOpen, true);

    // Verify fake product disappears
    final restoredFake = await reopenedIsar.itemModels.where().filter().namaEqualTo('FakeSoda').findFirst();
    expect(restoredFake, isNull);

    // Verify original data returns
    final restoredApple = await reopenedIsar.itemModels.where().filter().namaEqualTo('Apple').findFirst();
    expect(restoredApple, isNotNull);
    expect(restoredApple!.jumlahBarang, 90);

    // 7. PDF Test
    final pdfBill = await reopenedIsar.penjualanModels.where().filter().billNumberEqualTo('000001').findFirst();
    expect(pdfBill, isNotNull);
    await PdfService.generateInvoice(pdfBill!, store);
    final pdfFile = File('$downloadsPath/Invoice_000001.pdf');
    expect(pdfFile.existsSync(), true);
    expect(pdfFile.lengthSync() > 0, true);

    // Verify PDF Exported Audit Log
    final pdfAudit = await reopenedIsar.auditModels.where().filter().actionEqualTo('PDF_EXPORTED').findFirst();
    expect(pdfAudit, isNotNull);

    // 8. CSV Test
    final allBills = await reopenedIsar.penjualanModels.where().findAll();
    await CsvService.generateReport(allBills);
    
    // Locate the timestamped CSV file in downloads directory
    final downloadsDir = Directory(downloadsPath);
    final csvFiles = downloadsDir.listSync().where((f) => f.path.endsWith('.csv')).toList();
    expect(csvFiles.length, 1);
    expect(File(csvFiles.first.path).lengthSync() > 0, true);

    // Verify CSV Exported Audit Log
    final csvAudit = await reopenedIsar.auditModels.where().filter().actionEqualTo('CSV_EXPORTED').findFirst();
    expect(csvAudit, isNotNull);

    // 9. Stress Test
    // Insert 100 products and 100 bills
    final stressItems = List<ItemModel>.generate(100, (i) => ItemModel(
      nama: 'StressProduct_$i',
      code: 'SP_$i',
      jumlahBarang: 1000,
      quantity: 0,
      hargaDasar: 10 + i,
      hargaJual: 20 + i,
    ));

    final stressBills = List<PenjualanModel>.generate(100, (i) => PenjualanModel(
      billNumber: (i + 2).toString().padLeft(6, '0'),
      customerName: 'Customer_$i',
      items: [
        ProductItemModel(
          id: i,
          nama: 'StressProduct_$i',
          code: 'SP_$i',
          jumlahBarang: 1000,
          quantity: 1,
          hargaJual: 20 + i,
          hargaDasar: 10 + i,
          isSynced: true,
        )
      ],
      totalItem: 1,
      totalHarga: 20.0 + i,
      kasir: 1,
      createdAt: DateTime.now(),
    ));

    await reopenedIsar.writeTxn(() async {
      await reopenedIsar.itemModels.putAll(stressItems);
      await reopenedIsar.penjualanModels.putAll(stressBills);
    });

    // Timing Bills screen query
    final stopwatchBills = Stopwatch()..start();
    final fetchedBillsStress = await reopenedIsar.penjualanModels.where().findAll();
    stopwatchBills.stop();
    expect(fetchedBillsStress.length >= 101, true);
    print('Bills query time: ${stopwatchBills.elapsedMilliseconds} ms');

    // Timing Profit query
    final stopwatchProfit = Stopwatch()..start();
    final allSales = await reopenedIsar.penjualanModels.where().findAll();
    double totalRevenue = 0;
    double totalCost = 0;
    for (var b in allSales) {
      totalRevenue += b.totalHarga;
      for (var item in b.items) {
        totalCost += (item.hargaDasar ?? 0) * (item.quantity ?? 0);
      }
    }
    double totalProfit = totalRevenue - totalCost;
    stopwatchProfit.stop();
    print('Profit calculation time: ${stopwatchProfit.elapsedMilliseconds} ms');

    // Timing Audit query
    final stopwatchAudit = Stopwatch()..start();
    final fetchedAudits = await reopenedIsar.auditModels.where().sortByCreatedAtDesc().findAll();
    stopwatchAudit.stop();
    print('Audit query time: ${stopwatchAudit.elapsedMilliseconds} ms');

    expect(totalProfit >= 0, true);
    expect(fetchedAudits.isNotEmpty, true);

    // Make sure they are fast (under 100ms for 100 records)
    expect(stopwatchBills.elapsedMilliseconds < 100, true);
    expect(stopwatchProfit.elapsedMilliseconds < 100, true);
    expect(stopwatchAudit.elapsedMilliseconds < 100, true);

    await reopenedIsar.close();
  });
}
