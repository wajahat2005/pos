import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:due_kasir/controller/report_controller.dart';
import 'package:due_kasir/pages/drawer.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:due_kasir/utils/csv_service.dart';
import 'package:due_kasir/widget/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:go_router/go_router.dart';

class Profit extends HookWidget {
  const Profit({super.key});

  @override
  Widget build(BuildContext context) {
    final report = reportController.report.watch(context).value ?? [];
    final selectedDate = useState<DateTime>(DateTime.now());

    final filteredReport = report.where((item) {
      return DateFormat('yyyy-MM-dd').format(item.createdAt) == DateFormat('yyyy-MM-dd').format(selectedDate.value);
    }).toList();

    double totalSales = 0;
    double totalCost = 0;
    double totalProfit = 0;
    int billsCount = filteredReport.length;

    for (var sale in filteredReport) {
      totalSales += sale.totalHarga;
      double saleCost = 0;
      for (var item in sale.items) {
        saleCost += (item.hargaDasar ?? 0) * (item.quantity ?? 1);
      }
      totalCost += saleCost;
      totalProfit += (sale.totalHarga - saleCost);
    }

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
        title: const Text('Profit & Sales Report'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Report for: ${DateFormat('yyyy-MM-dd').format(selectedDate.value)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await CsvService.generateReport(filteredReport);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV Exported successfully!'), backgroundColor: Colors.green));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Error: $e'), backgroundColor: Colors.red));
                            }
                          },
                          icon: const Icon(Icons.table_chart, color: Colors.green),
                          label: const Text('Export Excel (CSV)'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            var results = await showCalendarDatePicker2Dialog(
                              context: context,
                              config: CalendarDatePicker2WithActionButtonsConfig(
                                calendarType: CalendarDatePicker2Type.single,
                              ),
                              dialogSize: const Size(325, 400),
                              value: [selectedDate.value],
                              borderRadius: BorderRadius.circular(15),
                            );
                            if (results != null && results.isNotEmpty && results.first != null) {
                              selectedDate.value = results.first!;
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Change Date'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text('Total Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(currency.format(totalSales), style: TextStyle(fontSize: 24, color: Colors.blue[900], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text('Total Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(currency.format(totalCost), style: TextStyle(fontSize: 24, color: Colors.orange[900], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text('Total Profit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(currency.format(totalProfit), style: TextStyle(fontSize: 24, color: Colors.green[900], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.purple[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text('Bills Count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(billsCount.toString(), style: TextStyle(fontSize: 24, color: Colors.purple[900], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Bills on this Date', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                filteredReport.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No sales found for this date.')))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredReport.length,
                        itemBuilder: (context, index) {
                          final bill = filteredReport[index];
                          final billNo = bill.billNumber ?? bill.id.toString();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.receipt, color: Colors.white)),
                              title: Text('Bill: $billNo - ${bill.customerName ?? "Admin"}'),
                              subtitle: Text(DateFormat('HH:mm').format(bill.createdAt)),
                              trailing: Text(currency.format(bill.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 24),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
