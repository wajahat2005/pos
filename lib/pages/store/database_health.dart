import 'dart:io';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';

class DatabaseHealthScreen extends StatefulWidget {
  const DatabaseHealthScreen({super.key});

  @override
  State<DatabaseHealthScreen> createState() => _DatabaseHealthScreenState();
}

class _DatabaseHealthScreenState extends State<DatabaseHealthScreen> {
  bool _isLoading = true;
  double _dbSizeMb = 0.0;
  int _productsCount = 0;
  int _billsCount = 0;
  int _auditLogsCount = 0;
  int _pendingPrintsCount = 0;
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await Database().db;
      
      final docDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory('${docDir.path}/Wajahat/database');
      int totalBytes = 0;
      if (await dbDir.exists()) {
        final files = dbDir.listSync();
        for (final f in files) {
          if (f is File && f.path.endsWith('.isar')) {
            totalBytes += await f.length();
          }
        }
      }
      _dbSizeMb = totalBytes / (1024 * 1024);

      _productsCount = await db.itemModels.count();
      _billsCount = await db.penjualanModels.count();
      _auditLogsCount = await db.auditModels.count();
      
      final allSales = await db.penjualanModels.where().findAll();
      _pendingPrintsCount = allSales.where((b) => b.printed == false).length;

      final lastBackupAudit = await db.auditModels
          .filter()
          .actionEqualTo('DATABASE_BACKUP')
          .sortByCreatedAtDesc()
          .findFirst();
      _lastBackupDate = lastBackupAudit?.createdAt;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading health metrics: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Health Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.health_and_safety, size: 40, color: Colors.green[700]),
                              const SizedBox(width: 16),
                              const Text(
                                'Database Metrics',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          _buildMetricRow('Database Storage Size', '${_dbSizeMb.toStringAsFixed(3)} MB', Icons.storage),
                          _buildMetricRow('Total Products in Inventory', '$_productsCount', Icons.shopping_bag),
                          _buildMetricRow('Total Bill History Records', '$_billsCount', Icons.receipt),
                          _buildMetricRow('Total Audit Log Entries', '$_auditLogsCount', Icons.analytics),
                          _buildMetricRow('Total Pending Prints', '$_pendingPrintsCount', Icons.print_disabled, color: _pendingPrintsCount > 0 ? Colors.orange[700] : null),
                          _buildMetricRow(
                            'Last Backup Date',
                            _lastBackupDate != null
                                ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastBackupDate!)
                                : 'Never Backup',
                            Icons.backup,
                            color: _lastBackupDate == null ? Colors.red[700] : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadHealthData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Metrics'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue[700], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
