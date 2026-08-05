import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:due_kasir/utils/pdf_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:isar/isar.dart';

class ExportService {
  static Future<void> exportBillsCSV() async {
    final db = await Database().db;
    final bills = await db.penjualanModels.where().findAll();

    List<List<dynamic>> rows = [];
    rows.add(["Bill Number", "Date", "Customer", "Items Count", "Total Amount", "Status"]);

    for (var bill in bills) {
      rows.add([
        bill.billNumber ?? bill.id,
        DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt),
        bill.customerName ?? 'Walk-in',
        bill.totalItem,
        bill.totalHarga,
        bill.printed ? "Printed" : "Pending",
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    Uint8List bytes = Uint8List.fromList(csv.codeUnits);
    await FileSaver.instance.saveFile(
      name: "bills_export_${DateFormat('yyyyMMdd').format(DateTime.now())}",
      bytes: bytes,
      ext: "csv",
      mimeType: MimeType.csv,
    );
  }

  static Future<void> exportAuditLogsCSV() async {
    final db = await Database().db;
    final logs = await db.auditModels.where().findAll();

    List<List<dynamic>> rows = [];
    rows.add(["Date", "Action", "Bill Number", "Customer", "Amount", "Details"]);

    for (var log in logs) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt ?? DateTime.now()),
        log.action,
        log.billNumber ?? '-',
        log.customerName ?? '-',
        log.amount ?? 0,
        log.details ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    Uint8List bytes = Uint8List.fromList(csv.codeUnits);
    await FileSaver.instance.saveFile(
      name: "audit_logs_${DateFormat('yyyyMMdd').format(DateTime.now())}",
      bytes: bytes,
      ext: "csv",
      mimeType: MimeType.csv,
    );
  }

  static Future<void> exportAllBillsPDF() async {
    final db = await Database().db;
    final bills = await db.penjualanModels.where().findAll();

    final pdf = pw.Document();
    
    // We create a simple table of all bills.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("All Bills Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}")),
          pw.TableHelper.fromTextArray(
            context: context,
            data: <List<String>>[
              <String>['Bill Number', 'Date', 'Customer', 'Items', 'Total', 'Status'],
              ...bills.map((b) => [
                b.billNumber ?? b.id.toString(),
                DateFormat('yyyy-MM-dd HH:mm').format(b.createdAt),
                b.customerName ?? 'Walk-in',
                b.totalItem.toString(),
                b.totalHarga.toString(),
                b.printed ? "Printed" : "Pending",
              ])
            ],
          ),
        ],
      ),
    );

    Uint8List bytes = await pdf.save();
    await FileSaver.instance.saveFile(
      name: "all_bills_${DateFormat('yyyyMMdd').format(DateTime.now())}",
      bytes: bytes,
      ext: "pdf",
      mimeType: MimeType.other,
    );
  }

  static Future<void> exportShopClosingReportPDF() async {
    final db = await Database().db;
    final allBills = await db.penjualanModels.where().findAll();
    
    final today = DateTime.now();
    final todayBills = allBills.where((b) => 
      b.createdAt.year == today.year && 
      b.createdAt.month == today.month && 
      b.createdAt.day == today.day
    ).toList();

    double todaySales = 0;
    double todayProfit = 0;
    int pendingPrints = 0;
    
    // Calculate top selling products
    Map<String, double> productSales = {};

    for (var bill in todayBills) {
      todaySales += bill.totalHarga;
      if (!bill.printed) pendingPrints++;
      
      for (var item in bill.items) {
        double profit = ((item.hargaJual ?? 0) - (item.hargaDasar ?? 0)).toDouble();
        todayProfit += profit * (item.quantity ?? 0);
        
        String key = item.nama ?? 'Unknown';
        productSales[key] = (productSales[key] ?? 0.0) + (item.quantity ?? 0.0);
      }
    }

    var sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topSelling = sortedProducts.take(5).toList();

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, child: pw.Text("Shop Closing Report - ${DateFormat('yyyy-MM-dd').format(today)}")),
            pw.SizedBox(height: 20),
            pw.Text("Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Today's Sales: Rs $todaySales"),
            pw.Text("Today's Profit: Rs $todayProfit"),
            pw.Text("Bills Count: ${todayBills.length}"),
            pw.Text("Pending Prints: $pendingPrints"),
            pw.SizedBox(height: 20),
            pw.Text("Top Selling Products", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (topSelling.isEmpty) pw.Text("No products sold today."),
            ...topSelling.map((e) => pw.Text("${e.key}: ${e.value} items")),
          ],
        ),
      ),
    );

    Uint8List bytes = await pdf.save();
    await FileSaver.instance.saveFile(
      name: "shop_closing_${DateFormat('yyyyMMdd').format(DateTime.now())}",
      bytes: bytes,
      ext: "pdf",
      mimeType: MimeType.other,
    );
  }
}
