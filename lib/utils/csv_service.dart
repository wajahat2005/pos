import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class CsvService {
  static Future<void> generateReport(List<PenjualanModel> bills) async {
    List<List<dynamic>> rows = [
      ['Date', 'Bill Number', 'Customer', 'Revenue', 'Cost', 'Profit']
    ];

    for (var bill in bills) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt);
      final billNo = bill.billNumber ?? '-';
      final customer = bill.customerName ?? '-';
      final revenue = bill.totalHarga;
      
      double cost = 0;
      for (var item in bill.items) {
        cost += (item.hargaDasar ?? 0) * (item.quantity ?? 0);
      }
      final profit = revenue - cost;

      rows.add([date, billNo, customer, revenue, cost, profit]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception("Downloads directory not found");
      final String timestamp = DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
      final file = File('${dir.path}/Sales_Report_$timestamp.csv');
      await file.writeAsString(csvData);

      final db = await Database().db;
      await db.writeTxn(() async {
        await db.auditModels.put(AuditModel(
          action: 'CSV_EXPORTED',
          details: 'CSV Sales Report successfully exported to ${file.path}',
        ));
      });
    } catch (e) {
      final db = await Database().db;
      await db.writeTxn(() async {
        await db.auditModels.put(AuditModel(action: 'CSV_EXPORT_FAILED', details: e.toString()));
      });
      rethrow;
    }
  }
}
