import 'package:due_kasir/controller/store_controller.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:due_kasir/utils/pdf_service.dart';
import 'package:due_kasir/utils/print_service.dart';
import 'package:due_kasir/pages/bills/saved_receipt_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:isar/isar.dart';
import 'package:due_kasir/widgets/universal_back_button.dart';
import 'package:due_kasir/model/audit_model.dart';

class PrintedBillsScreen extends StatefulWidget {
  const PrintedBillsScreen({super.key});

  @override
  State<PrintedBillsScreen> createState() => _PrintedBillsScreenState();
}

class _PrintedBillsScreenState extends State<PrintedBillsScreen> {
  List<PenjualanModel> _printedBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinted();
  }

  Future<void> _loadPrinted() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = await Database().db;
      final allSales = await db.penjualanModels.where().findAll();
      setState(() {
        _printedBills = allSales.where((b) => b.printed == true).toList();
        // Sort descending by printedAt
        _printedBills.sort((a, b) => (b.printedAt ?? b.createdAt).compareTo(a.printedAt ?? a.createdAt));
      });
    } catch (_) {}
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _reprintBill(PenjualanModel bill) async {
    final store = storeController.store.value.value;
    if (store == null) return;
    try {
      await PrintService.letsPrint(
        store: store,
        model: bill,
        kasir: 'Admin',
        customerName: bill.customerName,
      );
      final db = await Database().db;
      await db.writeTxn(() async {
        await db.auditModels.put(AuditModel(
          action: 'REPRINT_COMPLETED',
          billNumber: bill.billNumber,
          customerName: bill.customerName,
          amount: bill.totalHarga,
          details: 'Receipt reprinted from Printed Bills.',
        ));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reprinted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reprint failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = storeController.store.watch(context).value;

    return Scaffold(
      appBar: AppBar(
        leading: const UniversalBackButton(),
        title: const Text('Printed Bills History'),
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrinted,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _printedBills.isEmpty
                        ? const Center(child: Text('No printed bills found.', style: TextStyle(fontSize: 18)))
                        : SingleChildScrollView(
                            child: PaginatedDataTable(
                              columns: const [
                                DataColumn(label: Text('Bill No')),
                                DataColumn(label: Text('Customer')),
                                DataColumn(label: Text('Date Printed')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Actions')),
                              ],
                              source: _PrintedBillsDataSource(
                                bills: _printedBills,
                                onView: (bill) {
                                  if (store != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SavedReceiptPage(bill: bill, store: store),
                                      ),
                                    );
                                  }
                                },
                                onReprint: (bill) async {
                                  await _reprintBill(bill);
                                },
                                onPdf: (bill) async {
                                  if (store != null) {
                                    try {
                                      await PdfService.generateInvoice(bill, store);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported successfully!')));
                                    } catch (_) {}
                                  }
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PrintedBillsDataSource extends DataTableSource {
  final List<PenjualanModel> bills;
  final void Function(PenjualanModel bill) onView;
  final void Function(PenjualanModel bill) onReprint;
  final void Function(PenjualanModel bill) onPdf;

  _PrintedBillsDataSource({
    required this.bills,
    required this.onView,
    required this.onReprint,
    required this.onPdf,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= bills.length) return null;
    final bill = bills[index];

    return DataRow(
      cells: [
        DataCell(Text(bill.billNumber ?? bill.id.toString())),
        DataCell(Text(bill.customerName ?? 'Walk-in')),
        DataCell(Text(bill.printedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(bill.printedAt!) : DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt))),
        DataCell(Text(currency.format(bill.totalHarga))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => onView(bill),
                tooltip: 'View Receipt',
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.orange),
                onPressed: () => onReprint(bill),
                tooltip: 'Reprint',
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.purple),
                onPressed: () => onPdf(bill),
                tooltip: 'Export PDF',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => bills.length;

  @override
  int get selectedRowCount => 0;
}
