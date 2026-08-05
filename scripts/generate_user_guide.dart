// Run this script to generate User_Guide.pdf
// Usage: dart run scripts/generate_user_guide.dart

import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

void main() async {
  final pdf = pw.Document();

  pw.TextStyle subheading(pw.Font bold) => pw.TextStyle(font: bold, fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800);
  pw.TextStyle body(pw.Font regular) => pw.TextStyle(font: regular, fontSize: 12);

  final regularData = File('assets/fonts/NotoSans-Regular.ttf').readAsBytesSync();
  final boldData = File('assets/fonts/NotoSans-Bold.ttf').readAsBytesSync();
  final regular = pw.Font.ttf(regularData.buffer.asByteData());
  final bold = pw.Font.ttf(boldData.buffer.asByteData());

  // Page 1: Cover + Table of Contents
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 80),
        pw.Center(child: pw.Text('Wajahat POS', style: pw.TextStyle(font: bold, fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('User Guide', style: pw.TextStyle(font: regular, fontSize: 24, color: PdfColors.grey700))),
        pw.SizedBox(height: 5),
        pw.Center(child: pw.Text('Version 1.0.0', style: pw.TextStyle(font: regular, fontSize: 14, color: PdfColors.grey500))),
        pw.SizedBox(height: 40),
        pw.Divider(color: PdfColors.blue800, thickness: 2),
        pw.SizedBox(height: 30),
        pw.Text('Table of Contents', style: subheading(bold)),
        pw.SizedBox(height: 15),
        ...[
          '1. Add Product',
          '2. Edit Product',
          '3. Create Sale',
          '4. Reprint Bill',
          '5. Delete Bill',
          '6. Backup Database',
          '7. Restore Database',
          '8. Export PDF Invoice',
          '9. Export CSV Report',
          '10. Audit Logs',
        ].map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(item, style: body(regular)),
        )),
      ],
    ),
  ));

  // Helper to build a section
  pw.Widget section(String title, String description, List<String> steps) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: subheading(bold)),
        pw.SizedBox(height: 8),
        pw.Text(description, style: body(regular)),
        pw.SizedBox(height: 10),
        ...steps.asMap().entries.map((entry) => pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
          child: pw.Text('${entry.key + 1}. ${entry.value}', style: body(regular)),
        )),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 15),
      ],
    );
  }

  // Page 2: Sections 1-5
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        section('1. Add Product', 'Add new inventory items to the system.', [
          'Open the Inventory page from the side menu.',
          'Click the "Add Product" button.',
          'Fill in: Name, Code, Purchase Price, Sale Price, Stock Quantity, Low Stock Limit.',
          'Click "Save" to add the product.',
          'The product will appear in the Inventory list.',
        ]),
        section('2. Edit Product', 'Update product details or prices.', [
          'Open the Inventory page.',
          'Find the product you want to edit.',
          'Click the "Edit" icon next to the product.',
          'Modify the fields as needed.',
          'Click "Save" to update.',
          'Note: Editing a price does NOT change old bills. Old bills keep their original prices.',
        ]),
        section('3. Create Sale', 'Process a new sale transaction.', [
          'Open the Sales page (POS screen).',
          'Search or browse products on the left panel.',
          'Click a product to add it to the cart.',
          'Adjust quantities as needed.',
          'Enter customer name (optional).',
          'Click "Pay" to complete the sale.',
          'Stock will automatically decrease.',
          'A receipt will print if a printer is connected.',
        ]),
      ],
    ),
  ));

  // Page 3: Sections 4-7
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        section('4. Reprint Bill', 'Reprint an old receipt exactly as it was.', [
          'Open the Bills page from the side menu.',
          'Find the bill you want to reprint.',
          'Click the printer icon (orange) in the Actions column.',
          'The receipt will print with the original prices, quantities, and customer name.',
          'No data is recalculated. The reprint matches the original exactly.',
        ]),
        section('5. Delete Bill', 'Remove a bill and restore inventory.', [
          'Open the Bills page.',
          'Find the bill you want to delete.',
          'Click the delete icon (red).',
          'Confirm the deletion in the dialog.',
          'Stock quantities will automatically be restored.',
          'An audit log entry will be created for this action.',
        ]),
        section('6. Backup Database', 'Create a safety copy of all data.', [
          'Open Settings from the side menu.',
          'Set a Backup Folder Path (optional, defaults to Downloads).',
          'Click "Export Database".',
          'A file named backup_YYYY_MM_DD_HH_MM_SS.isar will be created.',
          'Store this file safely. It contains all your data.',
          'Recommended: Backup daily.',
        ]),
        section('7. Restore Database', 'Restore data from a backup file.', [
          'Open Settings from the side menu.',
          'Click "Restore Database".',
          'Read the warning carefully. Restoring will replace ALL current data.',
          'Select a backup .isar file.',
          'The app will validate the file, create an emergency backup, then restore.',
          'The application will restart automatically after restore.',
        ]),
      ],
    ),
  ));

  // Page 4: Sections 8-10
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        section('8. Export PDF Invoice', 'Generate a professional PDF invoice for a bill.', [
          'Open the Bills page.',
          'Find the bill you want to export.',
          'Click the PDF icon (purple) in the Actions column.',
          'A file named Invoice_[BillNumber].pdf will be saved to your Downloads folder.',
          'Open the PDF to verify: Shop Name, Bill Number, Customer, Items, and Total.',
        ]),
        section('9. Export CSV Report', 'Export sales data for spreadsheet analysis.', [
          'Open the Profit page from the side menu.',
          'Select the date for the report.',
          'Click "Export Excel (CSV)".',
          'A file named Sales_Report_YYYY_MM_DD_HH_MM_SS.csv will be saved.',
          'Open it in Excel or any spreadsheet application.',
          'Columns: Date, Bill Number, Customer, Revenue, Cost, Profit.',
        ]),
        section('10. Audit Logs', 'View a read-only history of important actions.', [
          'Open Audit Logs from the side menu.',
          'View the table showing: Date, Action, Bill Number, Customer, Amount, Details.',
          'Tracked actions include: DELETE_BILL, DATABASE_BACKUP, DATABASE_RESTORE, PDF_EXPORTED, CSV_EXPORTED.',
          'Failed actions are also logged: BACKUP_FAILED, RESTORE_FAILED, PDF_EXPORT_FAILED, CSV_EXPORT_FAILED, PRINT_FAILED.',
          'Audit logs cannot be edited or deleted.',
        ]),
        pw.SizedBox(height: 40),
        pw.Divider(color: PdfColors.blue800, thickness: 2),
        pw.SizedBox(height: 15),
        pw.Center(child: pw.Text('Wajahat POS v1.0.0 — Offline POS for Windows', style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey500))),
      ],
    ),
  ));

  final output = File('Wajahat_v1/User_Guide.pdf');
  await output.parent.create(recursive: true);
  await output.writeAsBytes(await pdf.save());
  print('User Guide generated: ${output.path}');
}
