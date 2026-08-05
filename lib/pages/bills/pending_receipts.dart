import 'package:due_kasir/controller/store_controller.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
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

class PendingReceiptsScreen extends StatefulWidget {
  const PendingReceiptsScreen({super.key});

  @override
  State<PendingReceiptsScreen> createState() => _PendingReceiptsScreenState();
}

class _PendingReceiptsScreenState extends State<PendingReceiptsScreen> {
  List<PenjualanModel> _pendingBills = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _selectedIds.clear();
    });
    try {
      final db = await Database().db;
      final allSales = await db.penjualanModels.where().findAll();
      setState(() {
        _pendingBills = allSales.where((b) => b.printed == false).toList();
      });
    } catch (_) {}
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _printBill(PenjualanModel bill) async {
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
        bill.printed = true;
        bill.printedAt = DateTime.now();
        await db.penjualanModels.put(bill);
        await db.auditModels.put(AuditModel(
          action: 'PRINT_COMPLETED',
          billNumber: bill.billNumber,
          customerName: bill.customerName,
          amount: bill.totalHarga,
          details: 'Receipt printed from Pending Center.',
        ));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed for #${bill.billNumber}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printSelected() async {
    if (_selectedIds.isEmpty) return;
    final selected = _pendingBills.where((b) => _selectedIds.contains(b.id)).toList();
    for (var bill in selected) {
      await _printBill(bill);
    }
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed printing selected receipts.'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _printAll() async {
    if (_pendingBills.isEmpty) return;
    for (var bill in _pendingBills) {
      await _printBill(bill);
    }
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed printing all pending receipts.'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: const Text('Are you sure you want to delete selected pending bills? Stock will be restored.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final db = Database();
    for (var id in _selectedIds) {
      await db.removePenjualan(id);
    }
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted selected pending bills and restored stock.')));
    }
  }

  Future<void> _deleteAll() async {
    if (_pendingBills.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Pending'),
        content: const Text('Are you sure you want to delete ALL pending bills? Stock will be restored.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final db = Database();
    for (var bill in _pendingBills) {
      await db.removePenjualan(bill.id!);
    }
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted all pending bills and restored stock.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = storeController.store.watch(context).value;

    return Scaffold(
      appBar: AppBar(
        leading: const UniversalBackButton(),
        title: const Text('Pending Print Center'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPending,
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
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : _printSelected,
                        icon: const Icon(Icons.print),
                        label: Text('Print Selected (${_selectedIds.length})'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pendingBills.isEmpty ? null : _printAll,
                        icon: const Icon(Icons.print),
                        label: Text('Print All Pending (${_pendingBills.length})'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                        icon: const Icon(Icons.delete),
                        label: Text('Delete Selected (${_selectedIds.length})'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pendingBills.isEmpty ? null : _deleteAll,
                        icon: const Icon(Icons.delete_forever),
                        label: Text('Delete All Pending (${_pendingBills.length})'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _pendingBills.isEmpty
                        ? const Center(child: Text('No pending receipts to print.', style: TextStyle(fontSize: 18)))
                        : SingleChildScrollView(
                            child: PaginatedDataTable(
                              columns: const [
                                DataColumn(label: Text('Select')),
                                DataColumn(label: Text('Bill No')),
                                DataColumn(label: Text('Customer')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Amount')),
                                DataColumn(label: Text('Actions')),
                              ],
                              source: _PendingBillsDataSource(
                                bills: _pendingBills,
                                selectedIds: _selectedIds,
                                onSelectChanged: (id, isSelected) {
                                  setState(() {
                                    if (isSelected == true) {
                                      _selectedIds.add(id);
                                    } else {
                                      _selectedIds.remove(id);
                                    }
                                  });
                                },
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
                                onPrint: (bill) async {
                                  await _printBill(bill);
                                  await _loadPending();
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

class _PendingBillsDataSource extends DataTableSource {
  final List<PenjualanModel> bills;
  final Set<int> selectedIds;
  final void Function(int id, bool? isSelected) onSelectChanged;
  final void Function(PenjualanModel bill) onView;
  final void Function(PenjualanModel bill) onPrint;
  final void Function(PenjualanModel bill) onPdf;

  _PendingBillsDataSource({
    required this.bills,
    required this.selectedIds,
    required this.onSelectChanged,
    required this.onView,
    required this.onPrint,
    required this.onPdf,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= bills.length) return null;
    final bill = bills[index];
    final isSelected = selectedIds.contains(bill.id);

    return DataRow(
      selected: isSelected,
      cells: [
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (val) => onSelectChanged(bill.id!, val),
          ),
        ),
        DataCell(Text(bill.billNumber ?? bill.id.toString())),
        DataCell(Text(bill.customerName ?? 'Walk-in')),
        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt))),
        DataCell(Text(currency.format(bill.totalHarga))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => onView(bill),
                tooltip: 'View',
              ),
              IconButton(
                icon: const Icon(Icons.print, color: Colors.green),
                onPressed: () => onPrint(bill),
                tooltip: 'Print',
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
  int get selectedRowCount => selectedIds.length;
}
