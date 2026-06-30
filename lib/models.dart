class Category {
  final int? id;
  final String name;
  final int? parentId;

  Category({this.id, required this.name, this.parentId});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'parentId': parentId};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'], name: map['name'], parentId: map['parentId']);
  }
}

class CafeTable {
  final int? id;
  final String number;
  final String location;
  bool isOccupied;

  CafeTable({this.id, required this.number, this.location = '', this.isOccupied = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'number': number, 'location': location, 'isOccupied': isOccupied ? 1 : 0};
  }

  factory CafeTable.fromMap(Map<String, dynamic> map) {
    return CafeTable(
      id: map['id'],
      number: map['number'].toString(),
      location: map['location'] ?? '',
      isOccupied: (map['isOccupied'] ?? 0) == 1,
    );
  }
}

class AppUser {
  final int? id;
  final String username;
  final String password;
  final String name;
  final String role; // 'admin' or 'cashier'

  AppUser({this.id, required this.username, required this.password, required this.name, required this.role});

  Map<String, dynamic> toMap() {
    return {'id': id, 'username': username, 'password': password, 'name': name, 'role': role};
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      role: map['role'],
    );
  }
}

class AppBluetoothDevice {
  final String? name;
  final String? address;

  AppBluetoothDevice(this.name, this.address);
}

class Product {
  final int? id;
  final String name;
  final double price;
  final double hpp; // Total HPP
  final double? priceBotol;
  final double? hppBotol;
  final String? hppDetails; // JSON String of breakdown
  final int categoryId;
  final String? imagePath;
  final String? barcode;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.hpp,
    this.priceBotol,
    this.hppBotol,
    this.hppDetails,
    required this.categoryId,
    this.imagePath,
    this.barcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'hpp': hpp,
      'priceBotol': priceBotol,
      'hppBotol': hppBotol,
      'hppDetails': hppDetails,
      'categoryId': categoryId,
      'imagePath': imagePath,
      'barcode': barcode,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      hpp: (map['hpp'] ?? 0).toDouble(),
      priceBotol: map['priceBotol'] != null ? (map['priceBotol'] as num).toDouble() : null,
      hppBotol: map['hppBotol'] != null ? (map['hppBotol'] as num).toDouble() : null,
      hppDetails: map['hppDetails'],
      categoryId: map['categoryId'],
      imagePath: map['imagePath'],
      barcode: map['barcode'],
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  String variant; // "Hot" or "Ice"

  CartItem({required this.product, this.quantity = 1, this.variant = "Hot"});

  double get unitPrice => (variant == "Ice" && product.priceBotol != null && product.priceBotol! > 0) ? product.priceBotol! : product.price;
  double get unitHpp => (variant == "Ice" && product.hppBotol != null && product.hppBotol! > 0) ? product.hppBotol! : product.hpp;

  double get totalPrice => unitPrice * quantity;
  double get totalHpp => unitHpp * quantity;
}

class TransactionHeader {
  final int? id;
  final DateTime dateTime;
  final double totalAmount;
  final double discount;
  final String paymentMethod;

  TransactionHeader({this.id, required this.dateTime, required this.totalAmount, this.discount = 0, required this.paymentMethod});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'totalAmount': totalAmount,
      'discount': discount,
      'paymentMethod': paymentMethod,
    };
  }

  factory TransactionHeader.fromMap(Map<String, dynamic> map) {
    return TransactionHeader(
      id: map['id'],
      dateTime: DateTime.parse(map['dateTime']),
      totalAmount: map['totalAmount'],
      discount: (map['discount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'],
    );
  }
}

class TransactionDetail {
  final int? id;
  final int transactionId;
  final String productName;
  final int quantity;
  final double price;
  final double hpp;

  TransactionDetail({this.id, required this.transactionId, required this.productName, required this.quantity, required this.price, required this.hpp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'hpp': hpp,
    };
  }
}

class Expense {
  final int? id;
  final String description;
  final double amount;
  final DateTime dateTime;

  Expense({this.id, required this.description, required this.amount, required this.dateTime});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
