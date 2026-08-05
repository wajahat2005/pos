import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:due_kasir/widget/logo_placeholder.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final StoreModel store;
  final PenjualanModel model;
  final String kasir;
  final String? customerName;

  const ReceiptPreviewDialog({
    super.key,
    required this.store,
    required this.model,
    required this.kasir,
    this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Receipt Preview / Checkout',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Receipt Content matching ESC/POS structure
                    LogoPlaceholder(logoPath: store.logoPath, size: 80),
                    const SizedBox(height: 8),
                    Text(
                      store.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${store.description}\n${store.phone}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black, thickness: 1.5),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('yyyy-MM-dd HH:mm').format(model.createdAt)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cashier:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(kasir),
                      ],
                    ),
                    if (customerName != null && customerName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(customerName!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black, thickness: 1.5),
                    const SizedBox(height: 8),
                    // Items
                    for (var i in model.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.nama ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i.quantity} x ${currency.format(i.hargaJual)}'),
                                Text(currency.format(i.quantity! * i.hargaJual!)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.black, thickness: 1.5),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${store.currencySymbol ?? "Rs"} ${currency.format(model.totalHarga).replaceAll(RegExp(r'^Rs\s*'), '')}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (store.footer != null && store.footer!.isNotEmpty)
                      Text(
                        store.footer!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Thank You For Visiting',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Designed & Developed by Mazhar Abbas',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('save_only'),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('save_pdf'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Save PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('save_print'),
                    icon: const Icon(Icons.print),
                    label: const Text('Save & Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
