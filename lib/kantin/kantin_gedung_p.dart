import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/my_cart_page.dart';

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

class KantinGedungP extends StatefulWidget {
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const KantinGedungP({
    super.key,
    required this.cart,
    required this.onCartUpdated,
  });

  @override
  State<KantinGedungP> createState() => _KantinGedungPState();
}

class _KantinGedungPState extends State<KantinGedungP> {
  static const List<String> _vendors = [
    'Ndokee Express',
    'Depot Mapan',
    'Depot Kita',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 35),
                  const Text(
                    'Kantin Gedung P',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 4, width: 350, color: const Color(0xFFFF7622)),
              const SizedBox(height: 30),
              // List Vendor
              Expanded(
                child: ListView.separated(
                  itemCount: _vendors.length,
                  separatorBuilder: (_, __) => const Divider(height: 40),
                  itemBuilder: (context, index) {
                    final name = _vendors[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => VendorMenuGedungPPage(
                                  vendorName: name,
                                  cart: widget.cart,
                                  onCartUpdated: widget.onCartUpdated,
                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 75,
                            height: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.restaurant_menu, size: 40),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Sen',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Tombol Cart
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF7622),
          elevation: 6,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => MyCartPage(
                      cart: widget.cart,
                      onClear: widget.onCartUpdated,
                    ),
              ),
            );
          },
          icon: const Icon(Icons.shopping_cart),
          label: Text('Cart', style: const TextStyle(fontFamily: 'Sen')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class VendorMenuGedungPPage extends StatefulWidget {
  final String vendorName;
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const VendorMenuGedungPPage({
    super.key,
    required this.vendorName,
    required this.cart,
    required this.onCartUpdated,
  });

  @override
  State<VendorMenuGedungPPage> createState() => _VendorMenuGedungPPageState();
}

class _VendorMenuGedungPPageState extends State<VendorMenuGedungPPage> {
  static final Map<String, Map<String, List<Map<String, dynamic>>>>
  kantinGedungPMenu = {
    'Ndokee Express': {
      'Nasi Goreng': [
        {'name': 'Nasi Goreng Ayam', 'price': 30000},
        {'name': 'Nasi Goreng Seafood', 'price': 30000},
      ],
      'Bakmi': [
        {'name': 'Mi Goreng Ayam', 'price': 30000},
        {'name': 'Mi Goreng Seafood', 'price': 30000},
      ],
    },
    'Depot Mapan': {
      'Nasi Pecel': [
        {'name': 'Nasi Pecel Ayam Goreng', 'price': 30000},
        {'name': 'Nasi Pecel Tempe Mendoan', 'price': 30000},
      ],
    },
    'Depot Kita': {
      'Menu': [
        {'name': 'Nasi Goreng', 'price': 30000},
        {'name': 'Mie Goreng', 'price': 30000},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final vendorMenus = kantinGedungPMenu[widget.vendorName]!;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 15),
                Text(
                  widget.vendorName,
                  style: const TextStyle(
                    fontFamily: 'Sen',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Strip Orange
            const SizedBox(height: 10),
            Container(height: 4, width: 350, color: const Color(0xFFFF7622)),
            const SizedBox(height: 30),
            // Menu List
            Expanded(
              child: ListView.builder(
                itemCount: vendorMenus.length,
                itemBuilder: (context, index) {
                  final categoryName = vendorMenus.keys.elementAt(index);
                  final menus = vendorMenus[categoryName]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...menus.map(
                          (menu) => Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              title: Text(
                                menu['name'],
                                style: const TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 18,
                                ),
                              ),
                              trailing: Text(
                                'Rp${menu['price']! ~/ 1000},000',
                                style: const TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              leading: GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text(
                                            'Tambah ke Keranjang?',
                                            style: TextStyle(fontFamily: 'Sen'),
                                          ),
                                          content: Text(
                                            menu['name'],
                                            style: const TextStyle(
                                              fontFamily: 'Sen',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text(
                                                'Batal',
                                                style: TextStyle(
                                                  fontFamily: 'Sen',
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text(
                                                'Ya',
                                                style: TextStyle(
                                                  fontFamily: 'Sen',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    widget.cart.addItem(
                                      widget.vendorName,
                                      menu,
                                    );
                                    widget.onCartUpdated();
                                  }
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(Icons.add, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Tombol Cart
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF7622),
          elevation: 6,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => MyCartPage(
                      cart: widget.cart,
                      onClear: widget.onCartUpdated,
                    ),
              ),
            );
          },
          icon: const Icon(Icons.shopping_cart),
          label: Text('Cart', style: const TextStyle(fontFamily: 'Sen')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
