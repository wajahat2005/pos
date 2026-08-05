import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<void> generateInvoice(PenjualanModel bill, StoreModel store) async {
    // Load NotoSans fonts for full Unicode support
    final regularFontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final baseStyle = pw.TextStyle(font: regularFont, fontSize: 12);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 12, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(font: boldFont, fontSize: 24, fontWeight: pw.FontWeight.bold);
    final invoiceStyle = pw.TextStyle(font: boldFont, fontSize: 18, fontWeight: pw.FontWeight.bold);
    final totalStyle = pw.TextStyle(font: boldFont, fontSize: 16, fontWeight: pw.FontWeight.bold);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (store.logoPath != null && store.logoPath!.isNotEmpty && File(store.logoPath!).existsSync()) ...[
              pw.Image(pw.MemoryImage(File(store.logoPath!).readAsBytesSync()), width: 60, height: 60),
              pw.SizedBox(height: 10),
            ] else ...[
              pw.Container(
                width: 60,
                height: 60,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('Logo Here', style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey700)),
              ),
              pw.SizedBox(height: 10),
            ],
            pw.Text(store.title, style: titleStyle),
            if (store.description.isNotEmpty) pw.Text(store.description, style: baseStyle),
            if (store.phone.isNotEmpty) pw.Text(store.phone, style: baseStyle),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('INVOICE', style: invoiceStyle),
            pw.SizedBox(height: 10),
            pw.Text('Bill No: ${bill.billNumber ?? '-'}', style: baseStyle),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt)}', style: baseStyle),
            if (bill.customerName != null && bill.customerName!.isNotEmpty) 
              pw.Text('Customer: ${bill.customerName}', style: baseStyle),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item', style: boldStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: boldStyle, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Price', style: boldStyle, textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: boldStyle, textAlign: pw.TextAlign.right)),
                  ],
                ),
                ...bill.items.map((e) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.nama ?? '', style: baseStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.quantity.toString(), style: baseStyle, textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs ${e.hargaJual}', style: baseStyle, textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rs ${(e.quantity ?? 0) * (e.hargaJual ?? 0)}', style: baseStyle, textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total: Rs ${bill.totalHarga}', style: totalStyle),
              ]
            ),
            if (store.footer != null) ...[
              pw.SizedBox(height: 30),
              pw.Center(child: pw.Text(store.footer!, style: baseStyle))
            ],
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Designed & Developed by Mazhar Abbas',
                style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception("Downloads directory not found");
      final file = File('${dir.path}/Invoice_${bill.billNumber}.pdf');
      await file.writeAsBytes(await pdf.save());

      final db = await Database().db;
      await db.writeTxn(() async {
        await db.auditModels.put(AuditModel(
          action: 'PDF_EXPORTED',
          billNumber: bill.billNumber,
          customerName: bill.customerName,
          amount: bill.totalHarga,
          details: 'PDF Invoice successfully exported to ${file.path}',
        ));
      });
    } catch (e) {
      final db = await Database().db;
      await db.writeTxn(() async {
        await db.auditModels.put(AuditModel(action: 'PDF_EXPORT_FAILED', details: e.toString()));
      });
      rethrow;
    }
  }
}
