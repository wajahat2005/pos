import 'package:due_kasir/controller/store_controller.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/pages/drawer.dart';
import 'package:due_kasir/widget/logo_placeholder.dart';
import 'package:due_kasir/widget/app_footer.dart';
import 'package:due_kasir/service/database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signals/signals_flutter.dart';
import 'dart:io';
import 'package:due_kasir/controller/selling_controller.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart' as usb_esc_printer_windows;
import 'package:due_kasir/utils/export_service.dart';

class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  final _storeFormKey = GlobalKey<FormState>();
  
  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController footer = TextEditingController();
  TextEditingController currencySymbol = TextEditingController(text: 'Rs');
  TextEditingController backupFolderPath = TextEditingController();
  
  String? logoPath;
  String printerSize = '80 mm';

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if available
    final state = storeController.store.value;
    final t = state.value;
    if (t != null) {
      title.text = t.title;
      description.text = t.description;
      phone.text = t.phone;
      footer.text = t.footer ?? '';
      currencySymbol.text = t.currencySymbol ?? 'Rs';
      backupFolderPath.text = t.backupFolderPath ?? '';
      logoPath = t.logoPath;
      printerSize = t.paperSize ?? '80 mm';
    }
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        logoPath = result.files.single.path;
      });
    }
  }

  void _saveStore(StoreModel? existingStore) {
    if (_storeFormKey.currentState!.validate()) {
      final val = StoreModel(
        id: existingStore?.id ?? DateTime.now().microsecondsSinceEpoch,
        title: title.text,
        description: description.text,
        phone: phone.text,
        footer: footer.text,
        logoPath: logoPath,
        currencySymbol: currencySymbol.text,
        paperSize: printerSize,
        backupFolderPath: backupFolderPath.text,
      );
      
      Database().addStore(val).whenComplete(() {
        storeController.store.refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store Settings Saved Successfully'),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingStore = storeController.store.watch(context).value;

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
        title: const Text('Settings'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _storeFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Information',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Shop Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: footer,
                    decoration: const InputDecoration(labelText: 'Receipt Footer Message'),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: currencySymbol,
                    decoration: const InputDecoration(labelText: 'Currency Symbol'),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: backupFolderPath,
                          decoration: const InputDecoration(labelText: 'Backup Folder Path'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                          if (selectedDirectory != null) {
                            setState(() {
                              backupFolderPath.text = selectedDirectory;
                            });
                          }
                        },
                        child: const Text('Browse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    initialValue: printerSize,
                    decoration: const InputDecoration(labelText: 'Printer Size'),
                    items: const [
                      DropdownMenuItem(value: '58 mm', child: Text('58 mm')),
                      DropdownMenuItem(value: '80 mm', child: Text('80 mm')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => printerSize = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Logo (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      LogoPlaceholder(logoPath: logoPath, size: 80),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Logo'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 50),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                      ),
                      if (logoPath != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() => logoPath = null),
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ]
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _saveStore(existingStore),
                    child: const Text('SAVE SETTINGS'),
                  ),
                  
                  const Divider(height: 64, thickness: 2),

                  const Text(
                    'Printer Testing',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Printer Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text('Printer: ${getIt.get<SellingController>().selectedPrint.watch(context)}'),
                          const SizedBox(height: 8),
                          Text('Last Test: ${existingStore?.lastPrinterTest != null ? DateFormat('yyyy-MM-dd HH:mm').format(existingStore!.lastPrinterTest!) : 'Never'}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Status: '),
                              if (existingStore?.lastPrinterResult == null)
                                const Text('⚪ Not Tested', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                              else if (existingStore?.lastPrinterResult == 'Working')
                                const Text('🟢 Connected', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                              else
                                const Text('🔴 Not Connected', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ensure your thermal printer is turned on, loaded with paper, and connected to this device.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final activeStore = storeController.store.value.value;
                      if (activeStore == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please configure and save store settings first.'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      
                      try {
                        final printName = getIt.get<SellingController>().selectedPrint.value;
                        final profile = await CapabilityProfile.load();
                        late CapabilityProfile winProfile;
                        if (Platform.isWindows) {
                          winProfile = await CapabilityProfile.load();
                        }
                        
                        final is58mm = activeStore.paperSize == '58 mm';
                        final generator = Generator(is58mm ? PaperSize.mm58 : PaperSize.mm80, Platform.isWindows ? winProfile : profile);
                        
                        List<int> bytes = [];
                        bytes += generator.text('*** TEST PRINT ***', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
                        bytes += generator.feed(1);
                        bytes += generator.text(activeStore.title, styles: const PosStyles(align: PosAlign.center, bold: true));
                        bytes += generator.text('Printer: $printName', styles: const PosStyles(align: PosAlign.center));
                        bytes += generator.text('Paper Size: ${activeStore.paperSize}', styles: const PosStyles(align: PosAlign.center));
                        bytes += generator.text('Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}', styles: const PosStyles(align: PosAlign.center));
                        bytes += generator.feed(1);
                        bytes += generator.hr();
                        bytes += generator.text('ESC/POS Connection: OK', styles: const PosStyles(align: PosAlign.center, bold: true));
                        bytes += generator.hr();
                        bytes += generator.feed(3);
                        bytes += generator.cut();
                        
                        if (Platform.isWindows) {
                          final res = await usb_esc_printer_windows.sendPrintRequest(bytes, printName);
                          if (res != 'success') {
                            throw Exception(res);
                          }
                        } else {
                          final success = await PrintBluetoothThermal.writeBytes(bytes);
                          if (!success) {
                            throw Exception('Bluetooth printing failed');
                          }
                        }
                        
                        final db = await Database().db;
                        await db.writeTxn(() async {
                          activeStore.lastPrinterTest = DateTime.now();
                          activeStore.lastPrinterResult = 'Working';
                          await db.storeModels.put(activeStore);
                          await db.auditModels.put(AuditModel(action: 'PRINT_TEST_SUCCESS', details: 'Printer $printName is working.'));
                        });
                        storeController.store.refresh();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test print sent successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        final db = await Database().db;
                        final activeStore = storeController.store.value.value;
                        if (activeStore != null) {
                          await db.writeTxn(() async {
                            activeStore.lastPrinterTest = DateTime.now();
                            activeStore.lastPrinterResult = 'Not Available';
                            await db.storeModels.put(activeStore);
                            await db.auditModels.put(AuditModel(action: 'PRINT_TEST_FAILED', details: 'Printer error: $e'));
                          });
                          storeController.store.refresh();
                        }

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Test Print Failed'),
                              content: Text('Could not send print request to printer.\n\nError: $e'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                              ],
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('RUN TEST PRINT'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const Divider(height: 64, thickness: 2),
                  
                  const Text(
                    'Data Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              String path = await Database().createBackUp();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Database Exported Successfully to $path')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('EXPORT DATABASE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['isar', 'zip'],
                            );
                            if (result != null && result.files.single.path != null) {
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('⚠️ WARNING', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    content: const Text(
                                      'Restoring a backup will:\n\n'
                                      '• Replace all current data\n'
                                      '• Replace inventory records\n'
                                      '• Replace bills history\n'
                                      '• Replace profit records\n'
                                      '• Restart the application\n\n'
                                      'A safety backup of current data will be created automatically.\n\n'
                                      'Are you sure you want to proceed?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          try {
                                            await Database().restoreDB(result.files.single.path!);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Restore Error: $e'), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Yes, Restore Data', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('RESTORE DATABASE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ExportService.exportBillsCSV();
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported Bills CSV successfully')));
                            } catch(e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                            }
                          },
                          icon: const Icon(Icons.table_view),
                          label: const Text('Export Bills CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ExportService.exportAllBillsPDF();
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported Bills PDF successfully')));
                            } catch(e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export Bills PDF'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ExportService.exportAuditLogsCSV();
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported Audit Logs successfully')));
                            } catch(e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                            }
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Export Audit Logs CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ExportService.exportShopClosingReportPDF();
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop Closing Report Exported')));
                            } catch(e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                            }
                          },
                          icon: const Icon(Icons.store),
                          label: const Text('Shop Closing Report'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/database-health');
                    },
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('VIEW DATABASE HEALTH METRICS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),
                  const Divider(height: 64, thickness: 2),
                  const Text(
                    'Danger Zone',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await _showResetDialog(context, 'Clear Business Data', 'This will delete all products, bills, and logs. Settings will be kept.');
                            if (confirm == true) {
                              await Database().clearBusinessData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business data cleared successfully')));
                              }
                            }
                          },
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Clear Business Data'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await _showResetDialog(context, 'Factory Reset', 'This will delete EVERYTHING and restart the app. This cannot be undone.');
                            if (confirm == true) {
                              await Database().factoryReset();
                            }
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Factory Reset'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showResetDialog(BuildContext context, String title, String message) {
    final tc = TextEditingController();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bool isButtonEnabled = tc.text == 'RESET';
            return AlertDialog(
              title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  const Text(
                    'WARNING: This action is permanent. Type RESET to continue:',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tc,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type RESET',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled ? Colors.red : Colors.grey,
                  ),
                  onPressed: isButtonEnabled
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
