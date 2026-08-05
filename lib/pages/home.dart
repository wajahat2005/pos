import 'dart:async';
import 'package:intl/intl.dart';
import 'package:due_kasir/controller/inventory_controller.dart';
import 'package:due_kasir/controller/report_controller.dart';
import 'package:due_kasir/controller/store_controller.dart';
import 'package:due_kasir/pages/drawer.dart';
import 'package:due_kasir/widget/app_footer.dart';
import 'package:due_kasir/widget/logo_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class CurrentDateTimeWidget extends StatefulWidget {
  const CurrentDateTimeWidget({super.key});

  @override
  State<CurrentDateTimeWidget> createState() => _CurrentDateTimeWidgetState();
}

class _CurrentDateTimeWidgetState extends State<CurrentDateTimeWidget> {
  late Timer _timer;
  String _formattedDateTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formatted = DateFormat('EEEE, d MMMM yyyy - HH:mm:ss').format(now);
    if (mounted) {
      setState(() {
        _formattedDateTime = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            _formattedDateTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final reportToday = reportController.reportToday.watch(context).value ?? [];
    final reportAll = reportController.reportAll.watch(context).value ?? [];
    final inventory = inventoryController.inventorys.watch(context).value ?? [];
    final lowStock = reportController.reportOutOfStcok.watch(context).value ?? [];
    final store = storeController.store.watch(context).value;
    final pendingCount = reportController.pendingPrintsCount.watch(context).value ?? 0;

    final String currencySymbol = store?.currencySymbol ?? 'Rs';

    double todaySales = 0;
    double todayProfit = 0;

    for (var sale in reportToday) {
      todaySales += sale.totalHarga;
      double cost = 0;
      for (var item in sale.items) {
        cost += (item.hargaDasar ?? 0) * (item.quantity ?? 1);
      }
      todayProfit += (sale.totalHarga - cost);
    }

    return Scaffold(
      drawer: const NavDrawer(),
      appBar: AppBar(
        title: const Text('Home Dashboard'),
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
                const SizedBox(height: 16),
                Center(
                  child: LogoPlaceholder(logoPath: store?.logoPath, size: 100),
                ),
                const SizedBox(height: 16),
                Text(
                  store?.title ?? 'Wajahat POS',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Center(child: CurrentDateTimeWidget()),
                const SizedBox(height: 24),
                const Divider(thickness: 2),
                const SizedBox(height: 24),
                const Text(
                  "TODAY'S SUMMARY",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Summary Cards
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2,
                  children: [
                    _buildSummaryCard(
                      context,
                      title: "Today's Sales",
                      value: "$currencySymbol ${todaySales.toStringAsFixed(0)}",
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    _buildSummaryCard(
                      context,
                      title: "Today's Profit",
                      value: "$currencySymbol ${todayProfit.toStringAsFixed(0)}",
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                    _buildSummaryCard(
                      context,
                      title: "Total Bills",
                      value: "${reportAll.length}",
                      icon: Icons.receipt,
                      color: Colors.orange,
                      onTap: () => context.go('/bills'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: "Pending Prints",
                      value: "$pendingCount",
                      icon: Icons.print_disabled,
                      color: Colors.amber,
                      onTap: () => context.go('/pending-receipts'),
                    ),
                    _buildSummaryCard(
                      context,
                      title: "Low Stock Items",
                      value: "${lowStock.length}",
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                    _buildSummaryCard(
                      context,
                      title: "Total Products",
                      value: "${inventory.length}",
                      icon: Icons.inventory_2,
                      color: Colors.purple,
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                const Divider(thickness: 2),
                const SizedBox(height: 24),
                
                const Text(
                  "QUICK ACTIONS",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Large Navigation Buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildNavButton(context, title: "NEW SALE", icon: Icons.point_of_sale, route: '/'),
                    _buildNavButton(context, title: "INVENTORY", icon: Icons.inventory, route: '/inventory'),
                    _buildNavButton(context, title: "BILLS", icon: Icons.receipt_long, route: '/bills'),
                    _buildNavButton(context, title: "PROFIT", icon: Icons.pie_chart, route: '/profit'),
                    _buildNavButton(context, title: "AUDIT LOGS", icon: Icons.history_edu, route: '/audit'),
                    _buildNavButton(context, title: "SETTINGS", icon: Icons.settings, route: '/store'),
                  ],
                ),
                const SizedBox(height: 32),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, {required String title, required IconData icon, required String route}) {
    return SizedBox(
      width: 220,
      height: 90,
      child: ElevatedButton.icon(
        onPressed: () => context.go(route),
        icon: Icon(icon, size: 36),
        label: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
