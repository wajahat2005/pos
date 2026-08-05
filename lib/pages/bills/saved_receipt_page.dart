import 'dart:convert';
import 'dart:io';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:due_kasir/utils/pdf_service.dart';
import 'package:due_kasir/utils/print_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavedReceiptPage extends StatelessWidget {
  final PenjualanModel bill;
  final StoreModel store;

  const SavedReceiptPage({
    super.key,
    required this.bill,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> snapshotData;
    if (bill.receiptSnapshot != null && bill.receiptSnapshot!.isNotEmpty) {
      try {
        snapshotData = jsonDecode(bill.receiptSnapshot!);
      } catch (_) {
        snapshotData = _fallbackSnapshot();
      }
    } else {
      snapshotData = _fallbackSnapshot();
    }

    final String title = snapshotData['storeTitle'] ?? '';
    final String desc = snapshotData['storeDescription'] ?? '';
    final String phone = snapshotData['storePhone'] ?? '';
    final String footer = snapshotData['storeFooter'] ?? '';
    final String logoPath = snapshotData['storeLogoPath'] ?? '';
    final String currencySymbol = snapshotData['storeCurrencySymbol'] ?? 'Rs';
    final String kasirName = snapshotData['kasirName'] ?? 'Admin';
    final String customerName = snapshotData['customerName'] ?? '';
    final String billNumber = snapshotData['billNumber'] ?? bill.billNumber ?? bill.id.toString();
    final String dateString = snapshotData['date'] ?? bill.createdAt.toIso8601String();
    final double totalHarga = (snapshotData['totalHarga'] as num?)?.toDouble() ?? bill.totalHarga;
    final List<dynamic> items = snapshotData['items'] ?? [];

    DateTime date;
    try {
      date = DateTime.parse(dateString);
    } catch (_) {
      date = bill.createdAt;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt View: #$billNumber'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              try {
                // Reprint using the snapshot items/details to keep it immutable
                final reprintBill = PenjualanModel(
                  id: bill.id,
                  billNumber: billNumber,
                  items: items.map((i) => ProductItemModel(
                    id: i['id'],
                    nama: i['nama'],
                    code: i['code'],
                    quantity: i['quantity'],
                    hargaJual: i['hargaJual'],
                    imagePath: i['imagePath'],
                  )).toList(),
                  totalHarga: totalHarga,
                  totalItem: items.length,
                  kasir: bill.kasir,
                  customerName: customerName,
                  createdAt: date,
                );
                
                final tempStore = StoreModel(
                  title: title,
                  description: desc,
                  phone: phone,
                  footer: footer,
                  logoPath: logoPath,
                  currencySymbol: currencySymbol,
                  paperSize: store.paperSize,
                );
                
                await PrintService.letsPrint(
                  store: tempStore,
                  model: reprintBill,
                  kasir: kasirName,
                  customerName: customerName,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt reprint request sent!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to print: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                final reprintBill = PenjualanModel(
                  id: bill.id,
                  billNumber: billNumber,
                  items: items.map((i) => ProductItemModel(
                    id: i['id'],
                    nama: i['nama'],
                    code: i['code'],
                    quantity: i['quantity'],
                    hargaJual: i['hargaJual'],
                    imagePath: i['imagePath'],
                  )).toList(),
                  totalHarga: totalHarga,
                  totalItem: items.length,
                  kasir: bill.kasir,
                  customerName: customerName,
                  createdAt: date,
                );

                final tempStore = StoreModel(
                  title: title,
                  description: desc,
                  phone: phone,
                  footer: footer,
                  logoPath: logoPath,
                  currencySymbol: currencySymbol,
                );

                await PdfService.generateInvoice(reprintBill, tempStore);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF Exported successfully!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (logoPath.isNotEmpty && File(logoPath).existsSync()) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.file(File(logoPath), width: 80, height: 80, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                          child: Icon(Icons.store, size: 40, color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    if (desc.isNotEmpty) Text(desc, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
                    if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black, thickness: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bill No:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(billNumber),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cashier:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(kasirName),
                      ],
                    ),
                    if (customerName.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(customerName),
                        ],
                      ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black, thickness: 1),
                    const SizedBox(height: 8),
                    const Text('ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    for (var i in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: i['imagePath'] != null && i['imagePath'].toString().isNotEmpty && File(i['imagePath'].toString()).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        File(i['imagePath'].toString()),
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Icon(Icons.photo, size: 20, color: Colors.grey[400]),
                                    ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i['nama'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${i['quantity']} x Rs ${i['hargaJual']}'),
                                ],
                              ),
                            ),
                            Text('Rs ${(i['quantity'] ?? 0) * (i['hargaJual'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black, thickness: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$currencySymbol ${currency.format(totalHarga).replaceAll(RegExp(r'^Rs\s*'), '')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (footer.isNotEmpty)
                      Text(footer, style: const TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text('Thank You For Visiting', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text('Designed & Developed by Mazhar Abbas', style: TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _fallbackSnapshot() {
    return {
      'storeTitle': store.title,
      'storeDescription': store.description,
      'storePhone': store.phone,
      'storeFooter': store.footer ?? '',
      'storeLogoPath': store.logoPath ?? '',
      'storeCurrencySymbol': store.currencySymbol ?? 'Rs',
      'kasirName': 'Admin',
      'customerName': bill.customerName ?? '',
      'billNumber': bill.billNumber ?? bill.id.toString(),
      'date': bill.createdAt.toIso8601String(),
      'totalHarga': bill.totalHarga,
      'totalItem': bill.totalItem,
      'items': bill.items.map((i) => {
        'id': i.id,
        'nama': i.nama,
        'code': i.code,
        'quantity': i.quantity,
        'hargaJual': i.hargaJual,
        'imagePath': i.imagePath ?? '',
      }).toList(),
    };
  }
}
