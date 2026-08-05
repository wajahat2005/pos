import 'dart:io';
import 'package:due_kasir/controller/inventory_controller.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/pages/inventory/inventory_adjustment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class InventoryList extends HookWidget {
  const InventoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = inventoryController.inventorys.watch(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      onChanged: (val) {
                        inventoryController.searchInventory.value = val;
                        inventoryController.inventorys.refresh();
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search by Item Name or Code...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      inventoryController.inventorySelected.value = null;
                      context.go('/inventory/form');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 56),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              inventory.map(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No Items Found', style: TextStyle(fontSize: 18)));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                      dataRowMaxHeight: 80,
                      columns: const [
                        DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                      rows: items.map((item) {
                        final bool isLowStock = item.jumlahBarang <= (item.lowStockLimit ?? 5);
                        const cellStyle = TextStyle(fontSize: 16);
                        return DataRow(cells: [
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: item.imagePath != null && item.imagePath!.isNotEmpty && File(item.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        File(item.imagePath!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt, color: Colors.grey[600], size: 24),
                                          const SizedBox(height: 2),
                                          const Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          DataCell(Text(item.nama, style: cellStyle)),
                          DataCell(Text(currency.format(item.hargaDasar), style: cellStyle)),
                          DataCell(Text(currency.format(item.hargaJual), style: cellStyle)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${item.jumlahBarang}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (isLowStock)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.red[700], borderRadius: BorderRadius.circular(4)),
                                    child: const Text('LOW STOCK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => InventoryAdjustmentDialog(
                                        item: item,
                                        onSaved: () {
                                          inventoryController.inventorys.refresh();
                                        },
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.tune, size: 18),
                                  label: const Text('Adjust'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    inventoryController.inventorySelected.value = item;
                                    context.go('/inventory/form');
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteItem(context, item),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
                error: (e, __) => Text('Error: $e'),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
  }

  void _deleteItem(BuildContext context, ItemModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item?'),
          content: Text('Are you sure you want to delete ${item.nama}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (item.id != null) {
                  await Database().deleteInventory(item.id!);
                  inventoryController.inventorys.refresh();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item Deleted Successfully'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
