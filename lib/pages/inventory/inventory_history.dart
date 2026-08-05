import 'dart:convert';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

class InventoryHistoryScreen extends StatefulWidget {
  const InventoryHistoryScreen({super.key});

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  List<AuditModel> _adjustments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = await Database().db;
      final audits = await db.auditModels.where().sortByCreatedAtDesc().findAll();
      setState(() {
        _adjustments = audits.where((a) => a.action == 'STOCK_ADJUSTMENT').toList();
      });
    } catch (_) {}
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Adjustment History'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: _adjustments.isEmpty
                  ? const Center(child: Text('No inventory adjustments found.', style: TextStyle(fontSize: 18)))
                  : SingleChildScrollView(
                      child: PaginatedDataTable(
                        header: const Text('Adjustment Logs'),
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Change')),
                          DataColumn(label: Text('Old Stock')),
                          DataColumn(label: Text('New Stock')),
                          DataColumn(label: Text('Reason')),
                        ],
                        source: _AdjustmentDataSource(adjustments: _adjustments),
                      ),
                    ),
            ),
    );
  }
}

class _AdjustmentDataSource extends DataTableSource {
  final List<AuditModel> adjustments;

  _AdjustmentDataSource({required this.adjustments});

  @override
  DataRow? getRow(int index) {
    if (index >= adjustments.length) return null;
    final audit = adjustments[index];
    
    String productName = 'Unknown';
    int change = 0;
    int oldStock = 0;
    int newStock = 0;
    String reason = audit.details ?? '';

    if (audit.details != null) {
      try {
        final decoded = jsonDecode(audit.details!);
        if (decoded is Map) {
          productName = decoded['productName'] ?? 'Unknown';
          change = decoded['change'] ?? 0;
          oldStock = decoded['oldStock'] ?? 0;
          newStock = decoded['newStock'] ?? 0;
          reason = decoded['reason'] ?? '';
        }
      } catch (_) {}
    }

    final changeText = change > 0 ? '+$change' : '$change';
    final changeColor = change > 0 ? Colors.green[700] : Colors.red[700];

    return DataRow(
      cells: [
        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(audit.createdAt ?? DateTime.now()))),
        DataCell(Text(productName)),
        DataCell(
          Text(
            changeText,
            style: TextStyle(color: changeColor, fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(oldStock.toString())),
        DataCell(Text(newStock.toString())),
        DataCell(Text(reason)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => adjustments.length;

  @override
  int get selectedRowCount => 0;
}
