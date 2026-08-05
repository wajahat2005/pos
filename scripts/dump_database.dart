import 'dart:io';
import 'dart:convert';
import 'package:isar/isar.dart';

// Import model files
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/customer_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/user_model.dart';
import 'package:due_kasir/model/auth_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/model/presence_model.dart';
import 'package:due_kasir/model/rent_item_model.dart';
import 'package:due_kasir/model/rent_model.dart';
import 'package:due_kasir/model/expenses_model.dart';
import 'package:due_kasir/model/salary_model.dart';
import 'package:due_kasir/model/due_payment_model.dart';
import 'package:due_kasir/model/audit_model.dart';

Map<String, dynamic> auditModelToJson(AuditModel val) => {
  'id': val.id,
  'action': val.action,
  'billNumber': val.billNumber,
  'customerName': val.customerName,
  'amount': val.amount,
  'details': val.details,
  'createdAt': val.createdAt?.toIso8601String(),
};

Map<String, dynamic> authModelToJson(AuthModel val) => {
  'id': val.id,
  'userId': val.user.value?.id,
  'userName': val.user.value?.nama,
  'createdAt': val.createdAt.toIso8601String(),
};

void main(List<String> args) async {
  if (args.isEmpty) {
    print('================================================================');
    print('Isar Database to Text Exporter');
    print('================================================================');
    print('Usage: dart run scripts/dump_database.dart <path-to-isar-file>');
    print('Example: dart run scripts/dump_database.dart "C:\\Users\\Noober\\OneDrive\\Documents\\default.isar"');
    print('================================================================');
    return;
  }

  final path = args[0];
  final file = File(path);
  if (!await file.exists()) {
    print('Error: Database file does not exist at: $path');
    return;
  }

  final directoryPath = file.parent.path;
  final dbName = file.uri.pathSegments.last.replaceAll('.isar', '');

  print('Initializing Isar binaries...');
  try {
    await Isar.initializeIsarCore(download: true);
  } catch (e) {
    print('Error initializing Isar core: $e');
    print('Make sure you have an internet connection to download the Isar engine, or run in the project root.');
  }

  print('Opening database: $dbName from directory: $directoryPath');
  Isar? isar;
  try {
    isar = await Isar.open(
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
        AuditModelSchema,
      ],
      directory: directoryPath,
      name: dbName,
      inspector: false,
    );
  } catch (e) {
    print('Error opening database: $e');
    print('If the database is currently open in the running application, please close the app first!');
    return;
  }

  print('Database opened successfully. Reading collections...');
  final Map<String, dynamic> dataDump = {};

  try {
    // 1. Store
    final stores = await isar.storeModels.where().findAll();
    dataDump['Store Settings'] = stores.map((s) => s.toJson()).toList();

    // 2. Items / Inventory
    final items = await isar.itemModels.where().findAll();
    dataDump['Inventory Items'] = items.map((i) => i.toJson()).toList();

    // 3. Customers
    final customers = await isar.customerModels.where().findAll();
    dataDump['Customers'] = customers.map((c) => c.toJson()).toList();

    // 4. Sales / Penjualan
    final sales = await isar.penjualanModels.where().findAll();
    dataDump['Sales Transactions'] = sales.map((s) => s.toJson()).toList();

    // 5. Users
    final users = await isar.userModels.where().findAll();
    dataDump['Users (Cashiers/Staff)'] = users.map((u) => u.toJson()).toList();

    // 6. Expenses
    final expenses = await isar.expensesModels.where().findAll();
    dataDump['Expenses'] = expenses.map((e) => e.toJson()).toList();

    // 7. Salaries
    final salaries = await isar.salaryModels.where().findAll();
    dataDump['Salaries'] = salaries.map((s) => s.toJson()).toList();

    // 8. Audits
    final audits = await isar.auditModels.where().findAll();
    dataDump['Audit Logs'] = audits.map((a) => auditModelToJson(a)).toList();

    // 9. Rent Items
    final rentItems = await isar.rentItemModels.where().findAll();
    dataDump['Rent Inventory Items'] = rentItems.map((r) => r.toJson()).toList();

    // 10. Rent Transactions
    final rents = await isar.rentModels.where().findAll();
    dataDump['Rent Transactions'] = rents.map((r) => r.toJson()).toList();

    // 11. Due Payments
    final duePayments = await isar.duePaymentModels.where().findAll();
    dataDump['Due Payments'] = duePayments.map((d) => d.toJson()).toList();

  } catch (e) {
    print('Error reading collections: $e');
  } finally {
    await isar.close();
  }

  // Create pretty human-readable string output
  final StringBuffer buffer = StringBuffer();
  buffer.writeln('================================================================');
  buffer.writeln('DUE KASIR - COMPLETE DATABASE DUMP');
  buffer.writeln('Export Time: ${DateTime.now().toIso8601String()}');
  buffer.writeln('Source File: $path');
  buffer.writeln('================================================================');
  buffer.writeln();

  dataDump.forEach((collectionName, list) {
    buffer.writeln('----------------------------------------------------------------');
    buffer.writeln('$collectionName (${list.length} records)');
    buffer.writeln('----------------------------------------------------------------');
    if (list.isEmpty) {
      buffer.writeln('(No records in this collection)');
    } else {
      for (var i = 0; i < list.length; i++) {
        buffer.writeln('[Record ${i + 1}]');
        final item = list[i] as Map<String, dynamic>;
        item.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
        buffer.writeln();
      }
    }
    buffer.writeln();
  });

  final exportFileName = dbName + '_readable_dump.txt';
  final exportFilePath = '$directoryPath\\$exportFileName';

  try {
    final exportFile = File(exportFilePath);
    await exportFile.writeAsString(buffer.toString());
    print('================================================================');
    print('SUCCESS!');
    print('Human-readable dump file generated at:');
    print(exportFilePath);
    print('You can now open this file in Notepad!');
    print('================================================================');
  } catch (e) {
    print('Error writing export file: $e');
  }
}
