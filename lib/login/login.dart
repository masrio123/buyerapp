import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- PERBAIKAN 1: Import AppShell ---
// Kita perlu mengimpor AppShell agar bisa menavigasi ke sana.
// Sesuaikan path ini jika AppShell Anda tidak berada di folder lib/.
import 'package:petraporter_buyer/app_shell.dart';
import '../services/login_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void handleLogin() async {
    // Tambahkan loading indicator jika perlu
    final auth = AuthService();
    final result = await auth.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    // Pastikan widget masih ada sebelum melanjutkan
    if (!mounted) return;

    if (result['success']) {
      final user = result['user'];
      print('Login berhasil! Selamat datang, ${user['nama']}');

      // --- PERBAIKAN 2: Navigasi setelah login ---
      // Ganti navigasi ke MainPage dengan navigasi ke AppShell.
      // pushAndRemoveUntil akan membersihkan tumpukan halaman,
      // sehingga pengguna tidak bisa kembali ke halaman login.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AppShell()),
        (Route<dynamic> route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Login Gagal'),
              content: Text(result['message']),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  void checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn =
        prefs.getString('token') != null; // Cek token lebih andal

    if (isLoggedIn) {
      // --- PERBAIKAN 3: Navigasi saat sudah login ---
      // Jika pengguna sudah login, langsung arahkan ke AppShell, bukan MainPage.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AppShell()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Logo
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  height: 300,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 30),
                // Login Form Container
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Email Field
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontFamily: 'Sen'),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          labelStyle: const TextStyle(
                            fontFamily: 'Sen',
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[150],
                          border: InputBorder.none,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      TextField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        style: const TextStyle(fontFamily: 'Sen'),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          labelStyle: const TextStyle(
                            fontFamily: 'Sen',
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.grey[150],
                          border: InputBorder.none,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7622),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 21),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'LOG IN',
                            style: TextStyle(
                              fontFamily: 'Sen',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
