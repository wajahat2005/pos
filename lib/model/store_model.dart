import 'package:isar/isar.dart';

part 'store_model.g.dart';

@collection
class StoreModel {
  Id? id = Isar.autoIncrement;
  late String title;
  late String description;
  late String phone;
  String? footer;
  String? subFooter;
  String? logoPath;
  String? currencySymbol;
  String? paperSize;
  String? backupFolderPath;
  DateTime? lastPrinterTest;
  String? lastPrinterResult;

  StoreModel({
    this.id,
    required this.title,
    required this.description,
    required this.phone,
    this.footer,
    this.subFooter,
    this.logoPath,
    this.currencySymbol,
    this.paperSize,
    this.backupFolderPath,
    this.lastPrinterTest,
    this.lastPrinterResult,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'phone': phone,
      'footer': footer,
      'subFooter': subFooter,
      'logoPath': logoPath,
      'currencySymbol': currencySymbol,
      'paperSize': paperSize,
      'backupFolderPath': backupFolderPath,
      'lastPrinterTest': lastPrinterTest?.toIso8601String(),
      'lastPrinterResult': lastPrinterResult,
    };
  }

  factory StoreModel.fromJson(json) {
    return StoreModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      phone: json['phone'],
      footer: json['footer'],
      subFooter: json['subFooter'],
      logoPath: json['logoPath'],
      currencySymbol: json['currencySymbol'],
      paperSize: json['paperSize'],
      backupFolderPath: json['backupFolderPath'],
      lastPrinterTest: json['lastPrinterTest'] != null ? DateTime.parse(json['lastPrinterTest']) : null,
      lastPrinterResult: json['lastPrinterResult'],
    );
  }
}
