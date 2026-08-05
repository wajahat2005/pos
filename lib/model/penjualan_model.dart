import 'dart:convert';

import 'package:isar/isar.dart';

part 'penjualan_model.g.dart';

@collection
class PenjualanModel {
  Id? id = Isar.autoIncrement;
  List<ProductItemModel> items = [];
  late int totalItem;
  late double totalHarga;
  late int kasir;
  int? pembeli;
  String? customerName;
  String? billNumber;
  String? keterangan;
  DateTime createdAt = DateTime.now();
  bool printed = false;
  DateTime? printedAt;
  String? receiptSnapshot;

  PenjualanModel({
    this.id,
    required this.items,
    required this.totalItem,
    required this.totalHarga,
    required this.kasir,
    this.pembeli,
    this.customerName,
    this.billNumber,
    this.keterangan,
    required this.createdAt,
    this.printed = false,
    this.printedAt,
    this.receiptSnapshot,
  });

  factory PenjualanModel.fromJson(json) {
    var itemsList = <ProductItemModel>[];
    if (json['items'] != null) {
      final itemsData = json['items'];
      if (itemsData is String) {
        final decoded = jsonDecode(itemsData);
        if (decoded is List) {
          itemsList = decoded.map((e) => ProductItemModel.fromJson(e)).toList();
        }
      } else if (itemsData is List) {
        itemsList = itemsData.map((e) => ProductItemModel.fromJson(e)).toList();
      }
    }
    return PenjualanModel(
      id: json['id'],
      items: itemsList,
      totalItem: json['totalItem'],
      totalHarga: json['totalHarga'],
      kasir: json['kasir'],
      pembeli: json['pembeli'],
      customerName: json['customerName'],
      billNumber: json['billNumber'],
      keterangan: json['keterangan'],
      createdAt: DateTime.parse(json['createdAt']),
      printed: json['printed'] ?? false,
      printedAt: json['printedAt'] != null ? DateTime.parse(json['printedAt']) : null,
      receiptSnapshot: json['receiptSnapshot'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'items': jsonEncode(items.map((e) => e.toJson()).toList()),
      'totalItem': totalItem,
      'totalHarga': totalHarga,
      'kasir': kasir,
      'pembeli': pembeli,
      'customerName': customerName,
      'billNumber': billNumber,
      'keterangan': keterangan,
      'createdAt': createdAt.toIso8601String(),
      'printed': printed,
      'printedAt': printedAt?.toIso8601String(),
      'receiptSnapshot': receiptSnapshot,
    };
  }
}

@embedded
class ProductItemModel {
  late int? id;
  late String? nama;
  late String? code;
  late String? deskripsi;
  late int? jumlahBarang;
  late int? quantity;
  late int? hargaDasar;
  late int? hargaJual;
  DateTime? barangMasuk;
  DateTime? barangKeluar;
  DateTime? createdAt;
  late bool? isSynced;
  String? imagePath;

  ProductItemModel({
    this.id,
    this.nama,
    this.code,
    this.deskripsi,
    this.jumlahBarang,
    this.quantity,
    this.hargaDasar,
    this.hargaJual,
    this.barangMasuk,
    this.barangKeluar,
    this.createdAt,
    this.isSynced,
    this.imagePath,
  });

  factory ProductItemModel.fromJson(json) {
    return ProductItemModel(
      id: json['id'],
      nama: json['nama'],
      code: json['code'],
      deskripsi: json['deskripsi'],
      jumlahBarang: json['jumlahBarang'],
      quantity: json['quantity'],
      hargaDasar: json['hargaDasar'],
      hargaJual: json['hargaJual'],
      barangMasuk: json['barangMasuk'] != null
          ? DateTime.tryParse(json['barangMasuk'].toString())
          : null,
      barangKeluar: json['barangKeluar'] != null
          ? DateTime.tryParse(json['barangKeluar'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isSynced: json['isSynced'],
      imagePath: json['imagePath'],
    );
  }

  toJson() {
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
      'isSynced': isSynced,
      'imagePath': imagePath,
    };
  }
}
