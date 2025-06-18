import 'package:flutter/material.dart';
import 'package:petraporter_buyer/delivery/my_cart_page.dart';
import 'package:petraporter_buyer/services/product_service.dart';
import '../models/tenant.dart';
import '../services/home_service.dart';
import '../models/cart_model.dart';

// --- PERUBAHAN --- Menambahkan konstanta warna untuk konsistensi
const Color _primaryColor = Color(0xFFFF7622);

class TenantPages extends StatefulWidget {
  final int vendorId;
  final String vendorName;
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const TenantPages({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.cart,
    required this.onCartUpdated,
  });

  @override
  State<TenantPages> createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPages> {
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
      if (mounted) {
        setState(() {
          _vendors = tenants;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching tenants: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // --- PERUBAHAN --- Snackbar dibuat floating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat vendor: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              70,
            ), // Memberi margin dari FAB
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 4, color: _primaryColor),
              const SizedBox(height: 20),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                )
              else if (_vendors.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Belum ada tenant yang tersedia saat ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _vendors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final tenant = _vendors[index];
                      return Card(
                        elevation: 4,
                        shadowColor: Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => VendorMenuTenantPage(
                                      vendorName: tenant.name,
                                      vendorId: tenant.tenantLocationId,
                                      cart: widget.cart,
                                      onCartUpdated: widget.onCartUpdated,
                                    ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: _primaryColor.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.storefront_outlined,
                                      size: 40,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    tenant.name,
                                    style: const TextStyle(
                                      fontFamily: 'Sen',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
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
          backgroundColor: _primaryColor,
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
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: const Text(
            'CART',
            style: TextStyle(
              fontFamily: 'Sen',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class VendorMenuTenantPage extends StatefulWidget {
  final String vendorName;
  final int vendorId;
  final CartModel cart;
  final VoidCallback onCartUpdated;

  const VendorMenuTenantPage({
    super.key,
    required this.vendorName,
    required this.vendorId,
    required this.cart,
    required this.onCartUpdated,
  });

  @override
  State<VendorMenuTenantPage> createState() => _VendorMenuTenantPageState();
}

class _VendorMenuTenantPageState extends State<VendorMenuTenantPage> {
  late Future<Map<String, Map<String, List<Map<String, dynamic>>>>> TenantMenu;

  @override
  void initState() {
    super.initState();
    TenantMenu = ProductService.fetchKantinMenu(widget.vendorId);
  }

  void _refreshMenu() {
    setState(() {
      TenantMenu = ProductService.fetchKantinMenu(widget.vendorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 28,
                    ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: double.infinity,
                color: _primaryColor,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: () async => _refreshMenu(),
                  child: FutureBuilder<
                    Map<String, Map<String, List<Map<String, dynamic>>>>
                  >(
                    future: TenantMenu,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Terjadi kesalahan saat mengambil data.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontFamily: 'Sen',
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'Menu tidak ditemukan',
                            style: TextStyle(fontFamily: 'Sen'),
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      if (!data.containsKey(widget.vendorName)) {
                        return const Center(
                          child: Text(
                            'Vendor tidak ditemukan di data menu',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Sen',
                            ),
                          ),
                        );
                      }
                      final vendorMenus = data[widget.vendorName]!;
                      return ListView.builder(
                        itemCount: vendorMenus.length,
                        itemBuilder: (context, index) {
                          final categoryName = vendorMenus.keys.elementAt(
                            index,
                          );
                          final menus = vendorMenus[categoryName]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4.0,
                                    bottom: 8.0,
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontFamily: 'Sen',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Divider(),
                                const SizedBox(height: 10),
                                if (menus.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 4.0,
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
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: menus.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, menuIndex) {
                                      final menu = menus[menuIndex];
                                      return Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 15,
                                                vertical: 5,
                                              ),
                                          title: Text(
                                            menu['name'],
                                            style: const TextStyle(
                                              fontFamily: 'Sen',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Rp${(menu['price'] / 1000).toStringAsFixed(0)}.000',
                                            style: const TextStyle(
                                              fontFamily: 'Sen',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _primaryColor,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: _primaryColor,
                                              size: 32,
                                            ),
                                            onPressed: () async {
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (_) => AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                      ),
                                                      title: const Text(
                                                        'Tambah ke Keranjang?',
                                                        style: TextStyle(
                                                          fontFamily: 'Sen',
                                                        ),
                                                      ),
                                                      content: Text(
                                                        menu['name'],
                                                        style: const TextStyle(
                                                          fontFamily: 'Sen',
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
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
                                                        FilledButton(
                                                          style:
                                                              FilledButton.styleFrom(
                                                                backgroundColor:
                                                                    _primaryColor,
                                                              ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
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
                                                // --- PERUBAHAN --- Snackbar dibuat floating
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${menu['name']} ditambahkan ke keranjang.',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 20,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
