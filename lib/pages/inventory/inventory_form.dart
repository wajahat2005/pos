import 'dart:io';
import 'package:due_kasir/controller/inventory_controller.dart';
import 'package:due_kasir/model/item_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class InventoryForm extends HookWidget {
  const InventoryForm({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryFormKey = useMemoized(GlobalKey<FormState>.new);
    final item = inventoryController.inventorySelected.watch(context);

    final editingName = useTextEditingController(text: item?.nama ?? '');
    final editingHargaDasar = useTextEditingController(text: (item?.hargaDasar ?? 0).toString());
    final editingHargaJual = useTextEditingController(text: (item?.hargaJual ?? 0).toString());
    final editingLowStockLimit = useTextEditingController(text: (item?.lowStockLimit ?? 5).toString());
    final editingStock = useTextEditingController(text: (item?.jumlahBarang ?? 0).toString());

    final imagePathState = useState<String?>(item?.imagePath);

    Future<void> pickAndCompressImage() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        final pickedPath = result.files.single.path!;
        final fileBytes = await File(pickedPath).readAsBytes();
        
        final image = img.decodeImage(fileBytes);
        if (image == null) return;

        img.Image resized = image;
        if (image.width > 300 || image.height > 300) {
          if (image.width > image.height) {
            resized = img.copyResize(image, width: 300);
          } else {
            resized = img.copyResize(image, height: 300);
          }
        }

        final compressedBytes = img.encodeJpg(resized, quality: 80);

        final docDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(docDir.path, 'Wajahat', 'images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = p.join(imagesDir.path, 'product_$timestamp.jpg');

        if (imagePathState.value != null) {
          final oldFile = File(imagePathState.value!);
          if (await oldFile.exists()) {
            try {
              await oldFile.delete();
            } catch (_) {}
          }
        }

        await File(newPath).writeAsBytes(compressedBytes);
        imagePathState.value = newPath;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item == null ? 'Add New Item' : 'Edit Item'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: inventoryFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: editingName,
                      decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Apple'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editingStock,
                      decoration: const InputDecoration(labelText: 'Stock Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editingLowStockLimit,
                      decoration: const InputDecoration(labelText: 'Low Stock Alert Limit', hintText: 'e.g. 5'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Product Image *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (imagePathState.value != null &&
                            imagePathState.value!.isNotEmpty &&
                            File(imagePathState.value!).existsSync()) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(imagePathState.value!),
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey[600], size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'No Image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilledButton.icon(
                              onPressed: pickAndCompressImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Upload Product Image'),
                            ),
                            if (imagePathState.value != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  imagePathState.value = null;
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 32, thickness: 1),
                    const Text('Pricing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: editingHargaDasar,
                            decoration: const InputDecoration(labelText: 'Purchase Price'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: editingHargaJual,
                            decoration: const InputDecoration(labelText: 'Sale Price'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        if (!inventoryFormKey.currentState!.validate()) return;

                        if (imagePathState.value == null || !File(imagePathState.value!).existsSync()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please upload a product image')),
                          );
                          return;
                        }

                        int stockVal = int.tryParse(editingStock.text) ?? 0;
                        int lowStock = int.tryParse(editingLowStockLimit.text) ?? 5;
                        int dasarVal = int.tryParse(editingHargaDasar.text) ?? 0;
                        int jualVal = int.tryParse(editingHargaJual.text) ?? 0;

                        if (item != null) {
                          final updatedItem = ItemModel(
                            id: item.id,
                            nama: editingName.text,
                            code: item.code,
                            quantity: 1,
                            hargaJual: jualVal,
                            hargaDasar: dasarVal,
                            jumlahBarang: stockVal,
                            createdAt: item.createdAt,
                            lowStockLimit: lowStock,
                            imagePath: imagePathState.value,
                          );

                          Database().updateInventory(updatedItem).whenComplete(() {
                            inventoryController.inventorys.refresh();
                            if (context.mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item Updated Successfully')));
                            }
                          });
                        } else {
                          final newItem = ItemModel(
                            id: DateTime.now().microsecondsSinceEpoch,
                            nama: editingName.text,
                            code: '',
                            quantity: 1,
                            hargaJual: jualVal,
                            hargaDasar: dasarVal,
                            jumlahBarang: stockVal,
                            createdAt: DateTime.now(),
                            lowStockLimit: lowStock,
                            imagePath: imagePathState.value,
                          );

                          Database().addInventory(newItem).whenComplete(() {
                            inventoryController.inventorys.refresh();
                            if (context.mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item Added Successfully')));
                            }
                          });
                        }
                      },
                      child: const Text('SAVE ITEM'),
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
}
