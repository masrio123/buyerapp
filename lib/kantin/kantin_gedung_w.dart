import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/my_cart_page.dart';
import 'package:petraporter_buyer/models/product.dart';
import 'package:petraporter_buyer/services/product_service.dart';
import 'kantin_gedung_p.dart';
import '../models/tenant.dart';
import '../services/home_service.dart';

class KantinGedungW extends StatefulWidget {
  final int vendorId;
  final String vendorName;
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const KantinGedungW({
    Key? key,
    required this.vendorId,
    required this.vendorName,
    required this.cart,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  State<KantinGedungW> createState() => _KantinGedungWState();
}

class _KantinGedungWState extends State<KantinGedungW> {
  List<Tenant> _vendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVendors();
  }

  Future<void> loadVendors() async {
    try {
      final tenants = await HomeService.fetchTenantByLocation(widget.vendorId);
      setState(() {
        _vendors = tenants;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching tenants: $e');
      setState(() => _isLoading = false);
    }
  }

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
              const SizedBox(height: 10),
              Container(height: 4, width: 350, color: const Color(0xFFFF7622)),
              const SizedBox(height: 30),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_vendors.isEmpty)
                const Center(child: Text('Tidak ada vendor ditemukan'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _vendors.length,
                    separatorBuilder: (_, __) => const Divider(height: 40),
                    itemBuilder: (context, index) {
                      final tenant = _vendors[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => VendorMenuGedungWPage(
                                    vendorName: tenant.name,
                                    vendorId: tenant.id,
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
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              tenant.name,
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
          label: const Text('Cart', style: TextStyle(fontFamily: 'Sen')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class VendorMenuGedungWPage extends StatefulWidget {
  final String vendorName;
  final int vendorId; // penting agar bisa fetch menu berdasarkan vendorId
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const VendorMenuGedungWPage({
    Key? key,
    required this.vendorName,
    required this.vendorId,
    required this.cart,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  State<VendorMenuGedungWPage> createState() => _VendorMenuGedungWPageState();
}

class _VendorMenuGedungWPageState extends State<VendorMenuGedungWPage> {
  late Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
  kantinGedungWMenu;

  @override
  void initState() {
    super.initState();
    kantinGedungWMenu = ProductService.fetchKantinMenu(widget.vendorId);
    kantinGedungWMenu.then((data) {
      print(widget.vendorId);
      print(widget.vendorName);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    widget.vendorName,
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 4, width: 350, color: const Color(0xFFFF7622)),
            const SizedBox(height: 30),
            Expanded(
              child: FutureBuilder<
                Map<String, Map<String, List<Map<String, dynamic>>>>
              >(
                future: kantinGedungWMenu,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Menu tidak ditemukan'));
                  }

                  final data = snapshot.data!;

                  if (!data.containsKey(widget.vendorName)) {
                    return const Center(
                      child: Text('Vendor tidak ditemukan di data menu'),
                    );
                  }

                  final vendorMenus = data[widget.vendorName]!;

                  return ListView.builder(
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
                            menus.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Menu tidak tersedia',
                                    style: TextStyle(
                                      fontFamily: 'Sen',
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                                : Column(
                                  children:
                                      menus
                                          .map(
                                            (menu) => Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
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
                                                  'Rp${(menu['price']! / 1000).toStringAsFixed(0)},000',
                                                  style: const TextStyle(
                                                    fontFamily: 'Sen',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                leading: GestureDetector(
                                                  onTap: () async {
                                                    // kode dialog tambah ke keranjang (sama seperti sebelumnya)
                                                  },
                                                  child: const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 30,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
