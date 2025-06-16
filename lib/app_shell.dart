import 'package:flutter/material.dart';
// PENTING: Sesuaikan path di bawah ini dengan struktur folder Anda!
import '../pages/main_pages.dart';
import '../pages/activity_pages.dart';
import '../pages/account_pages.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // State untuk melacak tab mana yang sedang aktif.
  // Kita bisa atur nilai awalnya, misal 0 untuk 'Order'.
  int _selectedIndex = 0;

  // Daftar semua halaman utama Anda. Urutannya HARUS SAMA dengan
  // urutan BottomNavigationBarItem.
  static const List<Widget> _widgetOptions = <Widget>[
    MainPage(), // Index 1
    ActivityPages(), // Index 2
    ProfilePage(), // Index 3
  ];

  // Fungsi yang akan dipanggil saat salah satu tab ditekan.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bagian body akan secara otomatis menampilkan halaman yang sesuai
      // dengan tab yang dipilih (_selectedIndex).
      body: _widgetOptions.elementAt(_selectedIndex),

      // Di sinilah kita mendefinisikan BottomNavigationBar-nya.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Order'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex:
            _selectedIndex, // Ini membuat icon yang aktif jadi berwarna.
        onTap: _onItemTapped, // Ini menghubungkan aksi tap dengan fungsi kita.
        selectedItemColor: const Color(0xFFFF7622), // Warna item aktif.
        unselectedItemColor: Colors.grey, // Warna item tidak aktif.
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Agar semua label terlihat.
      ),
    );
  }
}
