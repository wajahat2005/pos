import 'dart:io';
import 'package:due_kasir/controller/report_controller.dart';
import 'package:due_kasir/controller/selling_controller.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/pages/drawer.dart';
import 'package:due_kasir/pages/report/report_delete_dialog.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:due_kasir/utils/pdf_service.dart';
import 'package:due_kasir/utils/print_service.dart';
import 'package:due_kasir/widget/app_footer.dart';
import 'package:due_kasir/pages/bills/saved_receipt_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class Bills extends HookWidget {
  const Bills({super.key});

  @override
  Widget build(BuildContext context) {
    final report = reportController.report.watch(context).value ?? [];
    final searchQuery = useState<String>('');
    final showOnlyPending = useState<bool>(false);
    final activeDateFilter = useState<String>('This Month');
    final printName = getIt.get<SellingController>().selectedPrint.watch(context);

    final filteredReport = report.where((item) {
      if (showOnlyPending.value && item.printed == true) return false;
      if (searchQuery.value.isEmpty) return true;
      final q = searchQuery.value.toLowerCase();
      final billNo = item.billNumber?.toLowerCase() ?? item.id.toString();
      final customer = item.customerName?.toLowerCase() ?? 'Walk-in';
      final dateStr = DateFormat('yyyy-MM-dd').format(item.createdAt);
      
      final matchesBillOrCustomerOrDate = billNo.contains(q) || 
                                          customer.toLowerCase().contains(q) || 
                                          dateStr.contains(q);
      final matchesProduct = item.items.any((prod) =>
          (prod.nama?.toLowerCase().contains(q) ?? false) ||
          (prod.code?.toLowerCase().contains(q) ?? false) ||
          (prod.deskripsi?.toLowerCase().contains(q) ?? false));
          
      return matchesBillOrCustomerOrDate || matchesProduct;
    }).toList().reversed.toList();

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Bills History'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildFilterChip(context, 'Today', activeDateFilter, () {
                  reportController.dateRange.value = [
                    DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
                    DateTime.now().copyWith(hour: 23, minute: 59, second: 59),
                  ];
                }),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'This Week', activeDateFilter, () {
                  final now = DateTime.now();
                  final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0);
                  reportController.dateRange.value = [startOfWeek, now];
                }),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'This Month', activeDateFilter, () {
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  reportController.dateRange.value = [startOfMonth, now];
                }),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Custom Date Range', activeDateFilter, () async {
                  final picked = await showCalendarDatePicker2Dialog(
                    context: context,
                    config: CalendarDatePicker2WithActionButtonsConfig(
                      calendarType: CalendarDatePicker2Type.range,
                    ),
                    dialogSize: const Size(325, 400),
                    value: reportController.dateRange.value,
                    borderRadius: BorderRadius.circular(15),
                  );
                  if (picked != null && picked.length >= 2 && picked[0] != null && picked[1] != null) {
                    reportController.dateRange.value = [picked[0]!, picked[1]!];
                  }
                }),
                const Spacer(),
                Text(
                  'Range: ${DateFormat('yyyy-MM-dd').format(reportController.dateRange.value.first)} to ${DateFormat('yyyy-MM-dd').format(reportController.dateRange.value.last)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by Bill Number or Customer...',
                    ),
                    onChanged: (val) => searchQuery.value = val,
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Show Pending Prints Only', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Switch(
                      value: showOnlyPending.value,
                      onChanged: (val) => showOnlyPending.value = val,
                      activeColor: Colors.blue[700],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                  columns: const [
                    DataColumn(label: Text('Bill Number', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Printed At', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Print Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredReport.map((bill) {
                    final billNo = bill.billNumber ?? bill.id.toString();
                    final createdAtStr = DateFormat('yyyy-MM-dd HH:mm').format(bill.createdAt);
                    final printedAtStr = bill.printedAt != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(bill.printedAt!)
                        : 'Never';
                    final customer = bill.customerName ?? 'Walk-in';
                    
                    return DataRow(cells: [
                      DataCell(Text(billNo)),
                      DataCell(Text(createdAtStr)),
                      DataCell(Text(printedAtStr)),
                      DataCell(Text(customer)),
                      DataCell(Text(currency.format(bill.totalHarga))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bill.printed ? Colors.green[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: bill.printed ? Colors.green : Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                bill.printed ? '🟢 ' : '🟠 ',
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                bill.printed ? 'Printed' : 'Pending',
                                style: TextStyle(
                                  color: bill.printed ? Colors.green[800] : Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.receipt_long, color: Colors.blue),
                              onPressed: () async {
                                final store = await Database().getStore();
                                if (store != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SavedReceiptPage(bill: bill, store: store),
                                    ),
                                  );
                                }
                              },
                              tooltip: 'View Receipt',
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.teal),
                              onPressed: () => _showBillDetails(context, bill),
                              tooltip: 'Items Details',
                            ),
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.orange),
                              onPressed: () async {
                                final store = await Database().getStore();
                                if (store != null) {
                                  try {
                                    await PrintService.letsPrint(
                                      store: store,
                                      model: bill,
                                      kasir: 'Admin',
                                      customerName: bill.customerName,
                                      printName: printName,
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
                                        details: 'Receipt reprinted successfully.',
                                      ));
                                    });
                                    
                                    reportController.report.refresh();
                                    reportController.pendingPrintsCount.refresh();
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Reprint successful!'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    final db = await Database().db;
                                    await db.writeTxn(() async {
                                      await db.auditModels.put(AuditModel(
                                        action: 'PRINT_FAILED',
                                        billNumber: bill.billNumber,
                                        customerName: bill.customerName,
                                        amount: bill.totalHarga,
                                        details: 'Reprint failed: $e',
                                      ));
                                    });
                                    
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Printer Error'),
                                          content: Text('Could not reprint.\n\n$e'),
                                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Store settings not found.'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Reprint',
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.purple),
                              onPressed: () async {
                                final store = await Database().getStore();
                                if (store != null) {
                                  try {
                                    await PdfService.generateInvoice(bill, store);
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Exported successfully!'), backgroundColor: Colors.green));
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Error: $e'), backgroundColor: Colors.red));
                                  }
                                }
                              },
                              tooltip: 'Export PDF',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showShadDialog(
                                  context: context,
                                  builder: (context) => ReportDeleteDialog(id: bill.id!),
                                );
                              },
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  void _showBillDetails(BuildContext context, PenjualanModel bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bill Details - ${bill.billNumber ?? bill.id}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...bill.items.map((i) => ListTile(
                leading: i.imagePath != null && i.imagePath!.isNotEmpty && File(i.imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(i.imagePath!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.photo, color: Colors.grey[400]),
                      ),
                title: Text(i.nama ?? ''),
                trailing: Text('${i.quantity} x ${currency.format(i.hargaJual)}'),
              )),
              const Divider(),
              ListTile(
                title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(currency.format(bill.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, ValueNotifier<String> activeState, VoidCallback onTap) {
    final isSelected = activeState.value == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        activeState.value = label;
        onTap();
      },
    );
  }
}
