class Product {
  final int id;
  final String name;
  final int price;

  Product({required this.id, required this.name, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // Tambahkan parsing id
      name: json['name'],
      price: json['price'],
    );
  }
}

class Category {
  final String name;
  final List<Product> products;

  Category({required this.name, required this.products});

  factory Category.fromJson(Map<String, dynamic> json) {
    List<Product> products =
        (json['products'] as List).map((p) => Product.fromJson(p)).toList();

    return Category(name: json['category_name'], products: products);
  }
}

class TenantMenu {
  final String name;
  final List<Category> categories;

  TenantMenu({required this.name, required this.categories});

  factory TenantMenu.fromJson(Map<String, dynamic> json) {
    List<Category> categories =
        (json['categories'] as List).map((c) => Category.fromJson(c)).toList();

    return TenantMenu(name: json['tenant_name'], categories: categories);
  }
}
