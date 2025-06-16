class CartModel {
  final Map<String, List<Map<String, dynamic>>> _itemsByVendor = {};

  void addItem(String vendor, Map<String, dynamic> item) {
    _itemsByVendor.putIfAbsent(vendor, () => []);
    _itemsByVendor[vendor]!.add(item);
  }

  void removeItemByVendorAndIndex(String vendor, int index) {
    if (_itemsByVendor.containsKey(vendor)) {
      final items = _itemsByVendor[vendor]!;
      if (index >= 0 && index < items.length) {
        items.removeAt(index);
        if (items.isEmpty) {
          _itemsByVendor.remove(vendor);
        }
      }
    }
  }

  List<String> get vendors => _itemsByVendor.keys.toList();
  List<Map<String, dynamic>> itemsOf(String vendor) =>
      _itemsByVendor[vendor] ?? [];
  int get totalItems =>
      _itemsByVendor.values.fold(0, (sum, items) => sum + items.length);
  int get totalPrice => _itemsByVendor.values
      .expand((items) => items)
      .fold(0, (sum, it) => sum + (it['price'] as int));

  void clear() => _itemsByVendor.clear();
}
