import 'package:isar/isar.dart';

part 'audit_model.g.dart';

@collection
class AuditModel {
  Id? id;
  
  String? action;
  String? billNumber;
  String? customerName;
  double? amount;
  String? details;
  
  DateTime? createdAt;

  AuditModel({
    this.id,
    this.action,
    this.billNumber,
    this.customerName,
    this.amount,
    this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
