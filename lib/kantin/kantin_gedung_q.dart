import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/my_cart_page.dart';

import 'kantin_gedung_p.dart';

class KantinGedungQ extends StatefulWidget {
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const KantinGedungQ({Key? key, required this.cart, required this.onCartUpdated}) : super(key: key);

  @override
  State<KantinGedungQ> createState() => _KantinGedungQState();
}

class _KantinGedungQState extends State<KantinGedungQ> {
  static const List<String> _vendors = ['Ndokee Express', 'Depot Mapan', 'Depot Kita'];

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
                    'Kantin Gedung Q',
                    style: TextStyle(fontFamily: 'Sen', fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: 350,
                color: const Color(0xFFFF7622),
              ),
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
                            builder: (_) => VendorMenuGedungQPage(
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
                            style: const TextStyle(fontFamily: 'Sen', fontSize: 22, fontWeight: FontWeight.w600),
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
                builder: (_) => MyCartPage(
                  cart: widget.cart,
                  onClear: widget.onCartUpdated,
                ),
              ),
            );
          },
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Cart', style: TextStyle(fontFamily: 'Sen')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class VendorMenuGedungQPage extends StatefulWidget {
  final String vendorName;
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const VendorMenuGedungQPage({
    Key? key,
    required this.vendorName,
    required this.cart,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  State<VendorMenuGedungQPage> createState() => _VendorMenuGedungQPageState();
}

class _VendorMenuGedungQPageState extends State<VendorMenuGedungQPage> {
  static final Map<String, Map<String, List<Map<String, dynamic>>>> kantinGedungQMenu = {
    'Ndokee Express': {
      'Nasi Goreng': [
        {'name': 'Nasi Goreng Sosis', 'price': 30000},
        {'name': 'Nasi Goreng Kornet', 'price': 30000},
      ],
      'Bakmi': [
        {'name': 'Bakmi Sapi', 'price': 30000},
        {'name': 'Bakmi Seafood', 'price': 30000},
      ],
    },
    'Depot Mapan': {
      'Nasi Campur': [
        {'name': 'Nasi Campur Spesial', 'price': 30000},
        {'name': 'Nasi Campur Biasa', 'price': 30000},
      ],
    },
    'Depot Kita': {
      'Menu Favorit': [
        {'name': 'Ayam Penyet', 'price': 30000},
        {'name': 'Lele Goreng', 'price': 30000},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final vendorMenus = kantinGedungQMenu[widget.vendorName]!;

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
                  style: const TextStyle(fontFamily: 'Sen', fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Strip Orange
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 350,
              color: const Color(0xFFFF7622),
            ),
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
                          style: const TextStyle(fontFamily: 'Sen', fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...menus.map((menu) => Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            title: Text(menu['name'], style: const TextStyle(fontFamily: 'Sen', fontSize: 18)),
                            trailing: Text('Rp${menu['price']! ~/ 1000},000', style: const TextStyle(fontFamily: 'Sen', fontSize: 16, fontWeight: FontWeight.bold)),
                            leading: GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Tambah ke Keranjang?', style: TextStyle(fontFamily: 'Sen')),
                                    content: Text(menu['name'], style: const TextStyle(fontFamily: 'Sen', fontSize: 18, fontWeight: FontWeight.bold)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(fontFamily: 'Sen'))),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya', style: TextStyle(fontFamily: 'Sen'))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  widget.cart.addItem(widget.vendorName, menu);
                                  widget.onCartUpdated();
                                }
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                                child: const Icon(Icons.add, size: 18),
                              ),
                            ),
                          ),
                        )).toList(),
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
                builder: (_) => MyCartPage(
                  cart: widget.cart,
                  onClear: widget.onCartUpdated,
                ),
              ),
            );
          },
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Cart', style: TextStyle(fontFamily: 'Sen')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
