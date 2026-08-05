import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/pages/drawer.dart';
import 'package:due_kasir/widget/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';

class AuditLogs extends StatefulWidget {
  const AuditLogs({super.key});

  @override
  State<AuditLogs> createState() => _AuditLogsState();
}

class _AuditLogsState extends State<AuditLogs> {
  List<AuditModel> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final db = await Database().db;
    final data = await db.auditModels.where().sortByCreatedAtDesc().findAll();
    setState(() {
      logs = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Audit Logs'),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? const Center(child: Text("No audit logs found."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Bill Number', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Details', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: logs.map((log) {
                              return DataRow(cells: [
                                DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt ?? DateTime.now()))),
                                DataCell(Text(log.action ?? '')),
                                DataCell(Text(log.billNumber ?? '-')),
                                DataCell(Text(log.customerName ?? '-')),
                                DataCell(Text(log.amount != null ? 'Rs ${log.amount}' : '-')),
                                DataCell(Text(log.details ?? '')),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
