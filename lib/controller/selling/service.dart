import 'package:collection/collection.dart';

import 'package:due_kasir/model/item_model.dart';

class CartService {
  final _items = <ItemModel>[];

  List<ItemModel> get items => _items;

  Future<List<ItemModel>> loadProducts() =>
      Future.delayed(const Duration(milliseconds: 100) * 10, () => _items);

  void add(ItemModel item) {
    final isSame = _items.firstWhereOrNull((val) => val.code == item.code);
    if (isSame != null) {
      isSame.quantity = isSame.quantity + 1;
    } else {
      item.quantity = 1;
      _items.add(item);
    }
  }

  void setQuantity(ItemModel item, int quantity) {
    final existing = _items.firstWhereOrNull((val) => val.code == item.code);
    if (existing != null) {
      existing.quantity = quantity;
    }
  }

  void decrement(ItemModel item) {
    final existing = _items.firstWhereOrNull((val) => val.code == item.code);
    if (existing != null) {
      if (existing.quantity > 1) {
        existing.quantity = existing.quantity - 1;
      } else {
        _items.remove(existing);
      }
    }
  }

  void remove(ItemModel item) => _items.removeWhere((val) => val.code == item.code);

  void clear() => _items.clear();
}
