import 'package:flutter/material.dart';

// Kelas untuk menyimpan satu item di dalam keranjang, beserta catatannya.
class CartItem {
  final Map<String, dynamic> product;
  String note;

  CartItem({required this.product, this.note = ''});
}

class CartModel {
  final Map<String, List<CartItem>> _itemsByVendor = {};

  // Method untuk menambahkan CartItem ke vendor tertentu.
  void addItem(String vendor, CartItem cartItem) {
    _itemsByVendor.putIfAbsent(vendor, () => []);

    // Cek apakah produk yang sama sudah ada. Jika ada, tidak melakukan apa-apa.
    // Ini mencegah duplikasi item di keranjang.
    final existingIndex = _itemsByVendor[vendor]!.indexWhere(
      (item) => item.product['id'] == cartItem.product['id'],
    );

    if (existingIndex == -1) {
      _itemsByVendor[vendor]!.add(cartItem);
    }
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
  List<CartItem> itemsOf(String vendor) => _itemsByVendor[vendor] ?? [];

  int get totalItems =>
      _itemsByVendor.values.fold(0, (sum, items) => sum + items.length);

  int get totalPrice => _itemsByVendor.values
      .expand((items) => items)
      .fold(0, (sum, cartItem) => sum + (cartItem.product['price'] as int));

  void clear() => _itemsByVendor.clear();
}
