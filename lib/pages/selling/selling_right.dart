import 'dart:io';
import 'package:due_kasir/controller/selling/events.dart';
import 'package:due_kasir/controller/selling_controller.dart';
import 'package:due_kasir/controller/store_controller.dart';
import 'package:due_kasir/controller/report_controller.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:due_kasir/service/receipt_snapshot_service.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals/signals_flutter.dart';
import 'package:due_kasir/utils/print_service.dart';
import 'package:due_kasir/utils/pdf_service.dart';
import 'package:due_kasir/widget/receipt_preview_dialog.dart';
import 'package:due_kasir/widget/app_footer.dart';

class CartItemRow extends HookWidget {
  final ItemModel val;
  final bool overStock;
  final String currencySymbol;

  const CartItemRow({
    super.key,
    required this.val,
    required this.overStock,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final qtyController = useTextEditingController(text: '${val.quantity}');

    useEffect(() {
      if (qtyController.text != '${val.quantity}') {
        qtyController.text = '${val.quantity}';
      }
      return null;
    }, [val.quantity]);

    void handleQuantityInput(String value) {
      final parsed = int.tryParse(value);
      
      if (parsed == null || value.isEmpty) {
        getIt.get<SellingController>().dispatch(CartItemQuantitySet(val, 1));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid quantity. Reset to 1.'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      if (parsed <= 0) {
        getIt.get<SellingController>().dispatch(CartItemQuantitySet(val, 1));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity must be at least 1. Reset to 1.'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      if (parsed > val.jumlahBarang) {
        getIt.get<SellingController>().dispatch(CartItemQuantitySet(val, val.jumlahBarang));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only ${val.jumlahBarang} ${val.nama} available. Set to maximum.'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      getIt.get<SellingController>().dispatch(CartItemQuantitySet(val, parsed));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        color: overStock ? Colors.red[50] : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: val.imagePath != null && val.imagePath!.isNotEmpty && File(val.imagePath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(val.imagePath!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 16, color: Colors.grey[600]),
                        const Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 6, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  val.nama,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (overStock)
                  Text('Only ${val.jumlahBarang} available!', style: const TextStyle(color: Colors.red, fontSize: 12)),
                Text(
                  currency.format(val.hargaJual),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 28),
                onPressed: () {
                  getIt.get<SellingController>().dispatch(CartItemDecremented(val));
                },
              ),
              SizedBox(
                width: 60,
                height: 40,
                child: TextFormField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onFieldSubmitted: handleQuantityInput,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                onPressed: overStock ? null : () {
                  if (val.quantity >= val.jumlahBarang) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Only ${val.jumlahBarang} ${val.nama} items available'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  getIt.get<SellingController>().dispatch(CartItemAdded(val));
                },
              ),
            ],
          ),
          SizedBox(
            width: 110,
            child: Text(
              currency.format(val.hargaJual * val.quantity),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            onPressed: () {
              getIt.get<SellingController>().dispatch(CartItemRemoved(val));
            },
            tooltip: 'Remove item',
          ),
        ],
      ),
    );
  }
}

class SellingRight extends StatefulHookWidget {
  const SellingRight({super.key});

  @override
  SellingRightState createState() => SellingRightState();
}

class SellingRightState extends State<SellingRight> {

  @override
  Widget build(BuildContext context) {
    final store = storeController.store.watch(context);
    final printName = getIt.get<SellingController>().selectedPrint.watch(context);
    final kasir = getIt.get<SellingController>().kasir.watch(context);
    final list = getIt.get<SellingController>().cart.watch(context);
    
    final customerNameController = useTextEditingController();
    
    final currencySymbol = store.value?.currencySymbol ?? 'Rs';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CART', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: list.value == null || list.value!.items.isEmpty
                  ? const Center(child: Text('Cart is empty.', style: TextStyle(fontSize: 18, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: list.value!.items.length,
                      itemBuilder: (context, index) {
                        final val = list.value!.items[index];
                        final bool overStock = val.quantity > val.jumlahBarang;
                        
                        return CartItemRow(
                          key: ValueKey(val.code),
                          val: val,
                          overStock: overStock,
                          currencySymbol: currencySymbol,
                        );
                      },
                    ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            TextFormField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name (Required)',
                hintText: 'Enter customer name...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(
                    '$currencySymbol ${currency.format(list.value?.totalPrice ?? 0).replaceAll(RegExp(r'^Rs\s*'), '')}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: list.value == null || list.value!.items.isEmpty
                  ? null
                  : () async {
                      if (customerNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Name is required.'), backgroundColor: Colors.red));
                        return;
                      }

                      for (ItemModel p in list.value!.items) {
                        if (p.quantity > p.jumlahBarang) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.nama}: Only ${p.jumlahBarang} items available!'), backgroundColor: Colors.red));
                          return;
                        }
                        if (p.quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.nama}: Quantity must be at least 1'), backgroundColor: Colors.red));
                          return;
                        }
                      }

                      if (store.value?.paperSize == null || store.value!.paperSize!.isEmpty) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Paper Size Not Configured'),
                              content: const Text('Please go to Settings and configure the paper size before printing.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                            ),
                          );
                        }
                        return;
                      }

                      List<ProductItemModel> products = [];
                      for (ItemModel p in list.value!.items) {
                        products.add(
                          ProductItemModel()
                            ..id = p.id ?? DateTime.now().microsecondsSinceEpoch
                            ..nama = p.nama
                            ..code = p.code
                            ..quantity = p.quantity
                            ..hargaJual = p.hargaJual
                            ..hargaDasar = p.hargaDasar
                            ..deskripsi = p.deskripsi
                            ..jumlahBarang = p.jumlahBarang
                            ..isSynced = p.isSynced
                            ..imagePath = p.imagePath,
                        );
                      }

                      // Generate actual model and save to database immediately
                      final actualId = DateTime.now().microsecondsSinceEpoch;
                      final saveModel = PenjualanModel(
                        id: actualId,
                        items: products,
                        kasir: kasir?.id ?? 1,
                        keterangan: '',
                        totalHarga: list.value?.totalPrice ?? 0.0,
                        totalItem: list.value?.totalItem ?? 0,
                        pembeli: null,
                        customerName: customerNameController.text,
                        createdAt: DateTime.now(),
                        printed: false,
                      );
                      
                      // Save to database (generates real sequential billNumber)
                      await Database().addPenjualan(saveModel);

                      // Generate and store the immutable snapshot
                      final snapshot = ReceiptSnapshotService.buildSnapshot(
                        bill: saveModel,
                        store: store.value!,
                        kasir: kasir?.nama ?? 'Admin',
                      );
                      saveModel.receiptSnapshot = snapshot;
                      final dbInstance = await Database().db;
                      await dbInstance.writeTxn(() async {
                        await dbInstance.penjualanModels.put(saveModel);
                        await dbInstance.auditModels.put(AuditModel(
                          action: 'SALE_COMPLETED',
                          billNumber: saveModel.billNumber,
                          customerName: saveModel.customerName,
                          amount: saveModel.totalHarga,
                          details: 'Sale completed and saved automatically prior to preview.',
                        ));
                      });

                      // Show Preview Dialog using this saveModel containing real billNumber
                      final dynamic proceed = await showDialog<dynamic>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => ReceiptPreviewDialog(
                          store: store.value!,
                          model: saveModel,
                          kasir: kasir?.nama ?? 'Admin',
                          customerName: customerNameController.text,
                        ),
                      );

                      if (proceed == null || proceed == 'save_only') {
                        final db = await Database().db;
                        await db.writeTxn(() async {
                          await db.auditModels.put(AuditModel(
                            action: 'PRINT_PENDING',
                            billNumber: saveModel.billNumber,
                            customerName: saveModel.customerName,
                            amount: saveModel.totalHarga,
                            details: proceed == null
                                ? 'Sale saved without printing (dialog dismissed).'
                                : 'Sale saved without printing.',
                          ));
                        });
                      } else if (proceed == 'save_pdf') {
                        final db = await Database().db;
                        await db.writeTxn(() async {
                          await db.auditModels.put(AuditModel(
                            action: 'PRINT_PENDING',
                            billNumber: saveModel.billNumber,
                            customerName: saveModel.customerName,
                            amount: saveModel.totalHarga,
                            details: 'Sale saved with PDF export.',
                          ));
                        });
                        if (store.value != null) {
                          try {
                            await PdfService.generateInvoice(saveModel, store.value!);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: Colors.red));
                            }
                          }
                        }
                      } else if (proceed == 'save_print') {
                        bool printSuccess = false;
                        if (store.value != null) {
                          try {
                            await PrintService.letsPrint(
                              store: store.value!,
                              model: saveModel,
                              kasir: kasir?.nama ?? 'Admin',
                              customerName: customerNameController.text,
                              printName: printName,
                            );
                            printSuccess = true;
                          } catch (e) {
                            final db = await Database().db;
                            await db.writeTxn(() async {
                              await db.auditModels.put(AuditModel(
                                action: 'PRINT_PENDING',
                                billNumber: saveModel.billNumber,
                                customerName: saveModel.customerName,
                                amount: saveModel.totalHarga,
                                details: 'Bill saved successfully. Printer not connected. Added to Pending Prints.',
                              ));
                            });
                            
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Printer Error'),
                                  content: const Text('Bill saved successfully. Printer not connected. Added to Pending Prints.'),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                ),
                              );
                            }
                          }
                        }
                        
                        if (printSuccess) {
                          final db = await Database().db;
                          await db.writeTxn(() async {
                            saveModel.printed = true;
                            saveModel.printedAt = DateTime.now();
                            await db.penjualanModels.put(saveModel);
                            
                            await db.auditModels.put(AuditModel(
                              action: 'PRINT_COMPLETED',
                              billNumber: saveModel.billNumber,
                              customerName: saveModel.customerName,
                              amount: saveModel.totalHarga,
                              details: 'Receipt printed successfully.',
                            ));
                          });
                        }
                      }

                      customerNameController.clear();
                      await getIt.get<SellingController>().updateBatch(list.value!.items);
                      getIt.get<SellingController>().dispatch(CartPaid());
                      
                      // Refresh report signals for deferred printing dashboard updates
                      reportController.report.refresh();
                      reportController.reportToday.refresh();
                      reportController.reportAll.refresh();
                      reportController.pendingPrintsCount.refresh();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully!'), backgroundColor: Colors.green));
                      }
                    },
              icon: const Icon(Icons.print, size: 32),
              label: const Text('PRINT RECEIPT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 80),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
