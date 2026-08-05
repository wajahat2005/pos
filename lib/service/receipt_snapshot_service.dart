import 'dart:convert';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/store_model.dart';

class ReceiptSnapshotService {
  static String buildSnapshot({
    required PenjualanModel bill,
    required StoreModel store,
    required String kasir,
  }) {
    final Map<String, dynamic> data = {
      'storeTitle': store.title,
      'storeDescription': store.description,
      'storePhone': store.phone,
      'storeFooter': store.footer ?? '',
      'storeLogoPath': store.logoPath ?? '',
      'storeCurrencySymbol': store.currencySymbol ?? 'Rs',
      'kasirName': kasir,
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
    return jsonEncode(data);
  }
}
