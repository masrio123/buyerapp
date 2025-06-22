class Department {
  final int id;
  final String departmentName;

  Department({required this.id, required this.departmentName});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      departmentName: json['department_name'] ?? 'N/A',
    );
  }
}

// --- PERUBAHAN ---
// Kelas BankUser dihapus karena sudah tidak digunakan.

class Customer {
  final int id;
  final String customerName;
  final String identityNumber;
  final int userId;
  final Department department;
  // --- PERUBAHAN: Menghapus bankUser dan menggantinya dengan 3 field baru ---
  final String bankName;
  final String accountNumber;
  final String username; // Untuk A.N Rekening

  Customer({
    required this.id,
    required this.customerName,
    required this.identityNumber,
    required this.userId,
    required this.department,
    // --- PERUBAHAN ---
    required this.bankName,
    required this.accountNumber,
    required this.username,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Memastikan ada data 'customer' di dalam JSON
    final customerData = json['data'] ?? json;

    return Customer(
      id: customerData['id'] ?? 0,
      customerName: customerData['customer_name'] ?? 'No Name',
      identityNumber: customerData['identity_number'] ?? 'No ID',
      userId: customerData['user_id'] ?? 0,
      department: Department.fromJson(customerData['department'] ?? {}),
      // --- PERUBAHAN: Mengambil data bank langsung dari JSON ---
      bankName: customerData['bank_name'] ?? 'N/A',
      accountNumber: customerData['account_numbers'] ?? 'N/A',
      username: customerData['username'] ?? 'N/A',
    );
  }
}
