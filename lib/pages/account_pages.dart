import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

const Color _primaryColor = Color(0xFFFF7622);
const Color _backgroundColor = Color(0xFFFFFFFF);
const Color _textColor = Color(0xFF333333);
const Color _subtleTextColor = Colors.grey;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Customer? _customer;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Controller untuk field bank
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  Future<void> _fetchCustomer() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final customer = await CustomerService.fetchCustomerDetail();
      if (mounted) {
        setState(() {
          _customer = customer;
          _bankNameController.text = customer.bankName;
          _accountNumberController.text = customer.accountNumber;
          _usernameController.text = customer.username;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Gagal mengambil data customer: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data profil.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveBank() async {
    setState(() => _isSaving = true);
    final success = await CustomerService.updateCustomerBankDetails(
      bankName: _bankNameController.text,
      accountNumber: _accountNumberController.text,
      username: _usernameController.text,
    );
    if (mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Berhasil update data bank." : "Gagal update data bank.",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) _fetchCustomer();
    }
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCustomer,
        color: _primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_customer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 60),
              const SizedBox(height: 16),
              const Text(
                "Gagal memuat data profile.\nSilakan periksa koneksi Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _subtleTextColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _fetchCustomer,
                icon: const Icon(Icons.refresh),
                label: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 32),
        _buildInfoDetails(),
        const SizedBox(height: 32),
        if (_isSaving)
          const Center(child: CircularProgressIndicator(color: _primaryColor)),
        if (!_isSaving)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.green : _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isEditing ? _saveBank : _toggleEdit,
              child: Text(
                _isEditing ? 'Simpan Perubahan' : 'Edit Data Bank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        if (_isEditing)
          TextButton(onPressed: _toggleEdit, child: const Text("Batal")),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/avatar.png'),
          backgroundColor: Colors.black12,
        ),
        const SizedBox(height: 16),
        Text(
          _customer!.customerName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _customer!.identityNumber,
          style: const TextStyle(fontSize: 16, color: _subtleTextColor),
        ),
      ],
    );
  }

  Widget _buildInfoDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            label: "Jurusan",
            value: _customer!.department.departmentName,
            icon: Icons.school_outlined,
          ),
          const Divider(height: 1),
          _buildBankInfoRow(
            label: "Nama Bank",
            controller: _bankNameController,
            icon: Icons.business_center_outlined,
          ),
          const Divider(height: 1),
          _buildBankInfoRow(
            label: "Atas Nama",
            controller: _usernameController,
            icon: Icons.person_outline_rounded,
          ),
          const Divider(height: 1),
          _buildBankInfoRow(
            label: "Nomor Rekening",
            controller: _accountNumberController,
            icon: Icons.account_balance_wallet_outlined,
            isNumeric: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: _textColor)),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _subtleTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: _textColor)),
          const Spacer(),
          Expanded(
            child:
                _isEditing
                    ? TextField(
                      controller: controller,
                      textAlign: TextAlign.end,
                      keyboardType:
                          isNumeric ? TextInputType.number : TextInputType.text,
                      decoration: const InputDecoration.collapsed(
                        hintText: '...',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    )
                    : Text(
                      controller.text,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _subtleTextColor,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
