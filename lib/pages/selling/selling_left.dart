import 'dart:io';
import 'package:due_kasir/controller/inventory_controller.dart';
import 'package:due_kasir/controller/selling/events.dart';
import 'package:due_kasir/controller/selling_controller.dart';
import 'package:due_kasir/service/get_it.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals/signals_flutter.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class SellingLeft extends HookWidget {
  const SellingLeft({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final inventory = inventoryController.inventorys.watch(context).value ?? [];
    final searchQuery = useState<String>('');

    final filteredInventory = inventory.where((item) {
      if (searchQuery.value.isEmpty) return true;
      final queryWords = searchQuery.value.toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
      if (queryWords.isEmpty) return true;
      
      final nameLower = item.nama.toLowerCase();
      final descLower = (item.deskripsi ?? '').toLowerCase();
      final codeLower = item.code.toLowerCase();
      
      return queryWords.every((word) {
        return nameLower.contains(word) ||
               descLower.contains(word) ||
               codeLower.contains(word);
      });
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search product by name, barcode, SKU or desc...',
                  ),
                  onChanged: (val) => searchQuery.value = val,
                ),
              ),
              const SizedBox(width: 8),
              BarcodeKeyboardListener(
                bufferDuration: const Duration(milliseconds: 200),
                onBarcodeScanned: (barcode) {
                  final code = barcode.replaceAll('½', '-');
                  final item = inventory.where((e) => e.code == code).firstOrNull;
                  if (item != null && item.jumlahBarang > 0) {
                    getIt.get<SellingController>().dispatch(CartItemAdded(item));
                  }
                },
                child: const SizedBox.shrink(),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, size: 36, color: Colors.blue),
                onPressed: () async {
                  var res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
                  );
                  if (res is String && res != '-1') {
                    final item = inventory.where((e) => e.code == res).firstOrNull;
                    if (item != null && item.jumlahBarang > 0) {
                      getIt.get<SellingController>().dispatch(CartItemAdded(item));
                    }
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredInventory.isEmpty
              ? const Center(child: Text('No products found.'))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredInventory.length,
                  itemBuilder: (context, index) {
                    final item = filteredInventory[index];
                    final bool outOfStock = item.jumlahBarang <= 0;
                    return InkWell(
                      onTap: outOfStock ? null : () {
                        getIt.get<SellingController>().dispatch(CartItemAdded(item));
                      },
                      child: Card(
                        color: outOfStock ? Colors.grey[200] : Colors.white,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: item.imagePath != null && item.imagePath!.isNotEmpty && File(item.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        File(item.imagePath!),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey[400]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt, color: Colors.grey[600], size: 28),
                                          const SizedBox(height: 4),
                                          const Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      height: 38,
                                      child: Text(
                                        item.nama,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: outOfStock ? Colors.grey[600] : Colors.black87,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          currency.format(item.hargaJual),
                                          style: TextStyle(
                                            color: outOfStock ? Colors.grey[600] : Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text(
                                            outOfStock ? 'OUT' : 'Stk: ${item.jumlahBarang}',
                                            style: TextStyle(
                                              color: outOfStock ? Colors.red : Colors.grey[600],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
