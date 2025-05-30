import 'package:flutter/material.dart';
import 'activity_pages.dart';
import 'main_pages.dart';

void main() {
  runApp(const AccountPages());
}

class AccountPages extends StatelessWidget {
  const AccountPages({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ProfilePage(),
      theme: ThemeData(fontFamily: 'Sen'),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nomorRekening = "2160842219";
  String _atasNama = "REYHAN RENJIRO";
  String _selectedBank = "BRI";
  bool _isEditing = false;

  final TextEditingController _rekeningController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  final List<String> _bankList = ["BRI", "Mandiri", "BCA"];

  void _toggleEdit() {
    setState(() {
      _isEditing = true;
      _rekeningController.text = _nomorRekening;
      _namaController.text = _atasNama;
    });
  }

  void _saveRekening() {
    setState(() {
      _nomorRekening = _rekeningController.text;
      _atasNama = _namaController.text;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSizeTitle = screenWidth * 0.07;
    double fontSizeSubTitle = screenWidth * 0.05;
    double fontSizeText = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage('assets/customer.png'),
              ),
              const SizedBox(height: 12),
              Text(
                'Reyhan Renjiro',
                style: TextStyle(
                  fontSize: fontSizeTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: fontSizeSubTitle,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              const ProfileItem(label: "Jurusan", value: "Informatika"),
              const ProfileItem(label: "Angkatan", value: "2021"),
              const ProfileItem(label: "NRP", value: "c14210106"),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nomor Rekening",
                  style: TextStyle(fontSize: fontSizeText, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 5),
              _isEditing
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _rekeningController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizeText,
                        ),
                        decoration: InputDecoration(
                          hintText: "Nomor Rekening",
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _namaController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizeText,
                        ),
                        decoration: InputDecoration(
                          hintText: "Atas Nama",
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items:
                            _bankList.map((bank) {
                              return DropdownMenuItem(
                                value: bank,
                                child: Text(bank),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBank = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: _saveRekening,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7622),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Simpan",
                            style: TextStyle(
                              fontSize: fontSizeText,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nomorRekening,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSizeText,
                              ),
                            ),
                            Text(
                              "a.n $_atasNama",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fontSizeText,
                              ),
                            ),
                            Text(
                              "Bank $_selectedBank",
                              style: TextStyle(
                                fontSize: fontSizeText,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7622),
                        ),
                        onPressed: _toggleEdit,
                        child: const Text(
                          "Ganti",
                          style: TextStyle(
                              color: Colors.white,
                          fontSize: 18),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              HorizontalSlideRoute(page: const MainPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              HorizontalSlideRoute(page: ActivityPages()),
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
    );
  }
}

class ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const ProfileItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSizeText = screenWidth * 0.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSizeText, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeText),
        ),
        const SizedBox(height: 19),
        const Divider(),
      ],
    );
  }
}
