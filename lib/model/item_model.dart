import 'package:isar/isar.dart';

part 'item_model.g.dart';

@collection
class ItemModel {
  Id? id = Isar.autoIncrement;
  String nama;
  String code;
  String? deskripsi;
  int jumlahBarang;
  int quantity;
  int hargaDasar;
  int hargaJual;
  DateTime? barangMasuk;
  DateTime? barangKeluar;
  DateTime? createdAt;
  bool isSynced;
  int? lowStockLimit;
  String? imagePath;
  ItemModel({
    this.id,
    required this.nama,
    this.code = '',
    this.deskripsi,
    required this.jumlahBarang,
    required this.quantity,
    required this.hargaDasar,
    required this.hargaJual,
    this.barangMasuk,
    this.barangKeluar,
    this.createdAt,
    this.isSynced = true,
    this.lowStockLimit = 5,
    this.imagePath,
  }) {
    if (code.isEmpty) {
      code = 'PROD_${DateTime.now().microsecondsSinceEpoch}';
    }
  }
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nama': nama,
      'code': code,
      'deskripsi': deskripsi,
      'jumlahBarang': jumlahBarang,
      'quantity': quantity,
      'hargaDasar': hargaDasar,
      'hargaJual': hargaJual,
      'barangMasuk': barangMasuk?.toIso8601String(),
      'barangKeluar': barangKeluar?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'lowStockLimit': lowStockLimit,
      'imagePath': imagePath,
    };
  }

  factory ItemModel.fromJson(json) {
    return ItemModel(
      id: json['id'],
      nama: json['nama'],
      code: json['code'],
      deskripsi: json['deskripsi'] != null ? json['deskripsi'] as String : null,
      jumlahBarang: json['jumlahBarang'],
      quantity: json['quantity'],
      hargaDasar: json['hargaDasar'],
      hargaJual: json['hargaJual'],
      barangMasuk: json['barangMasuk'] != null
          ? DateTime.parse(json['barangMasuk'])
          : null,
      barangKeluar: json['barangKeluar'] != null
          ? DateTime.parse(json['barangKeluar'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lowStockLimit: json['lowStockLimit'] ?? 5,
      imagePath: json['imagePath'],
    );
  }
}
