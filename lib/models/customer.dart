class Department {
  final int id;
  final String departmentName;

  Department({required this.id, required this.departmentName});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(id: json['id'], departmentName: json['department_name']);
  }
}

class BankUser {
  final int id;
  final String username;
  final String accountNumber;

  BankUser({
    required this.id,
    required this.username,
    required this.accountNumber,
  });

  factory BankUser.fromJson(Map<String, dynamic> json) {
    return BankUser(
      id: json['id'],
      username: json['username'],
      accountNumber: json['account_number'],
    );
  }
}

class Customer {
  final int id;
  final String customerName;
  final String identityNumber;
  final int userId;
  final Department department;
  final BankUser bankUser;

  Customer({
    required this.id,
    required this.customerName,
    required this.identityNumber,
    required this.userId,
    required this.department,
    required this.bankUser,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      customerName: json['customer_name'],
      identityNumber: json['identity_number'],
      userId: json['user_id'],
      department: Department.fromJson(json['department']),
      bankUser: BankUser.fromJson(json['bank_user']),
    );
  }
}
