import 'package:flutter/material.dart';
import 'package:petraporter_buyer/pages/account_pages.dart';

import 'main_pages.dart';

class ActivityPages extends StatelessWidget {
  final List<Order> orders = [
    Order(
      date: '24 Maret 2025',
      porter: 'Jovan',
      id: '1101',
      items: [
        RestaurantOrder(
          name: 'Ndokee Express',
          items: [
            OrderItem(name: 'Nasi Goreng Ayam', quantity: 1, price: 30000),
            OrderItem(name: 'Nasi Goreng Hongkong', quantity: 1, price: 30000),
          ],
        ),
        RestaurantOrder(
          name: 'Depot Kita',
          items: [
            OrderItem(name: 'Mie Goreng', quantity: 1, price: 30000),
            OrderItem(name: 'Nasi Empal', quantity: 1, price: 30000),
          ],
          note: 'extra garam sama msg',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Sen',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Activity',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.receipt_long, size: 36),
                title: Text(
                  order.date,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Porter: ${order.porter}'),
                    Text('Order ID: ${order.id}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _showOrderDetail(context, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF7622),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text('Details', style: TextStyle(fontSize: 12)),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                HorizontalSlideRoute(page: const MainPage()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                HorizontalSlideRoute(page: (AccountPages())),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFF7622),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          iconSize: 35,
          unselectedFontSize: 15,
          selectedFontSize: 15,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text("Date: ${order.date}\n"),
                      for (final resto in order.items) ...[
                        Text(
                          resto.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        for (final item in resto.items)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.name} x${item.quantity}'),
                              ),
                              Text('Rp${item.price}'),
                            ],
                          ),
                        if (resto.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Catatan: ${resto.note!}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        Divider(),
                      ],
                      SizedBox(height: 10),
                      Text(
                        "TOTAL PAYMENT",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Price'),
                          Text('Rp${order.totalPrice()}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Delivery Fee'), Text('Rp6000')],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp${order.totalPrice() + 6000}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF7622),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class HorizontalSlideRoute extends PageRouteBuilder {
  final Widget page;

  HorizontalSlideRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Slide dari kanan
          const end = Offset.zero;
          const curve = Curves.ease;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}

// Model
class Order {
  final String date;
  final String porter;
  final String id;
  final List<RestaurantOrder> items;

  Order({
    required this.date,
    required this.porter,
    required this.id,
    required this.items,
  });

  int totalPrice() {
    return items
        .expand((e) => e.items)
        .fold(0, (sum, item) => sum + item.price);
  }
}

class RestaurantOrder {
  final String name;
  final List<OrderItem> items;
  final String? note;

  RestaurantOrder({required this.name, required this.items, this.note});
}

class OrderItem {
  final String name;
  final int quantity;
  final int price;

  OrderItem({required this.name, required this.quantity, required this.price});
}
