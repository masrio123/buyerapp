import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan path import dengan struktur folder Anda
import 'package:petraporter_buyer/app_shell.dart';
import 'package:petraporter_buyer/login/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petra Porter',
      theme: ThemeData(fontFamily: 'Sen'),
      // PENTING: Halaman utama sekarang adalah AuthCheck, si 'penjaga gerbang'.
      home: const AuthCheck(),
    );
  }
}

/// Widget ini bertugas memeriksa status login dan mengarahkan pengguna
/// ke halaman yang benar (LoginPage atau AppShell).
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Future<bool> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    // Cek berdasarkan keberadaan token, ini lebih andal.
    return prefs.getString('token') != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfLoggedIn(),
      builder: (context, snapshot) {
        // Selama proses pengecekan, tampilkan layar loading.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika sudah login (snapshot.data == true), tampilkan AppShell.
        if (snapshot.hasData && snapshot.data == true) {
          return const AppShell();
        }

        // Jika tidak, tampilkan LoginPage.
        return const LoginPage();
      },
    );
  }
}
