import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'models.dart';

Future<void> setupDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<String> getDbPath(String name) async {
  return join(await getDatabasesPath(), name);
}

Future<Database> openMobileDatabase(String path, Function onCreate) async {
  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          parentId INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          price REAL,
          hpp REAL,
          priceBotol REAL,
          hppBotol REAL,
          hppDetails TEXT,
          categoryId INTEGER,
          imagePath TEXT,
          barcode TEXT,
          FOREIGN KEY (categoryId) REFERENCES categories (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dateTime TEXT,
          totalAmount REAL,
          discount REAL,
          paymentMethod TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE transaction_details (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transactionId INTEGER,
          productName TEXT,
          variant TEXT,
          quantity INTEGER,
          price REAL,
          hpp REAL,
          FOREIGN KEY (transactionId) REFERENCES transactions (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT,
          amount REAL,
          dateTime TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE tables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number TEXT,
          location TEXT,
          isOccupied INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          password TEXT,
          name TEXT,
          role TEXT
        )
      ''');
      // Seed data
      await db.insert('users', {
        'username': 'admin',
        'password': '123',
        'name': 'Administrator',
        'role': 'admin'
      });
      await db.insert('users', {
        'username': 'kasir',
        'password': '123',
        'name': 'Kasir GM',
        'role': 'cashier'
      });
      await db.insert('categories', {'name': 'MANUAL BREW', 'parentId': null});
      await db.insert('categories', {'name': 'ES KOPI CUP/BOTOL', 'parentId': null});
      
      for (int i = 1; i <= 15; i++) {
        await db.insert('tables', {'number': '$i', 'location': 'Lantai 1', 'isOccupied': 0});
      }
    },
  );
}

Future<List<Category>> getMobileCategories(Database db) async {
  var res = await db.query('categories', where: 'parentId IS NULL');
  return res.map((c) => Category.fromMap(c)).toList();
}

Future<void> insertMobileCategory(Database db, Category category) async {
  await db.insert('categories', category.toMap());
}

Future<List<CafeTable>> getMobileTables(Database db) async {
  var res = await db.query('tables');
  return res.map((t) => CafeTable.fromMap(t)).toList();
}

Future<void> insertMobileTable(Database db, CafeTable table) async {
  await db.insert('tables', table.toMap());
}

Future<void> updateMobileTable(Database db, CafeTable table) async {
  await db.update('tables', table.toMap(), where: 'id = ?', whereArgs: [table.id]);
}

Future<void> deleteMobileTable(Database db, int id) async {
  await db.delete('tables', where: 'id = ?', whereArgs: [id]);
}

Future<List<AppUser>> getMobileUsers(Database db) async {
  var res = await db.query('users');
  return res.map((u) => AppUser.fromMap(u)).toList();
}

Future<void> insertMobileUser(Database db, AppUser user) async {
  await db.insert('users', user.toMap());
}

Future<void> updateMobileUser(Database db, AppUser user) async {
  await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
}

Future<void> deleteMobileUser(Database db, int id) async {
  await db.delete('users', where: 'id = ?', whereArgs: [id]);
}

Future<AppUser?> loginMobile(Database db, String username, String password) async {
  var res = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]);
  if (res.isNotEmpty) {
    return AppUser.fromMap(res.first);
  }
  return null;
}

Future<List<Product>> getMobileProductsByCategory(Database db, int categoryId) async {
  var res = await db.query('products', where: 'categoryId = ?', whereArgs: [categoryId]);
  return res.map((p) => Product.fromMap(p)).toList();
}

Future<List<Product>> getMobileAllProducts(Database db) async {
  var res = await db.query('products');
  return res.map((p) => Product.fromMap(p)).toList();
}

Future<void> insertMobileProduct(Database db, Product product) async {
  await db.insert('products', product.toMap());
}

Future<void> updateMobileProduct(Database db, Product product) async {
  await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
}

Future<void> insertMobileTransaction(Database db, TransactionHeader header, List<CartItem> items) async {
  await db.transaction((txn) async {
    int id = await txn.insert('transactions', header.toMap());
    for (var item in items) {
      await txn.insert('transaction_details', {
        'transactionId': id,
        'productName': item.product.name,
        'variant': item.variant,
        'quantity': item.quantity,
        'price': item.unitPrice,
        'hpp': item.unitHpp,
      });
    }
  });
}

Future<List<TransactionHeader>> getMobileTransactions(Database db, DateTime? start, DateTime? end) async {
  String? where;
  List<dynamic>? whereArgs;
  if (start != null && end != null) {
    where = 'dateTime BETWEEN ? AND ?';
    whereArgs = [start.toIso8601String(), end.toIso8601String()];
  }
  var res = await db.query('transactions', where: where, whereArgs: whereArgs, orderBy: 'dateTime DESC');
  return res.map((t) => TransactionHeader.fromMap(t)).toList();
}

Future<List<Map<String, dynamic>>> getMobileTransactionDetails(Database db, int transactionId) async {
  return await db.query('transaction_details', where: 'transactionId = ?', whereArgs: [transactionId]);
}

Future<int> insertMobileExpense(Database db, Expense expense) async {
  return await db.insert('expenses', expense.toMap());
}

Future<List<Expense>> getMobileExpenses(Database db, DateTime? start, DateTime? end) async {
  String? where;
  List<dynamic>? whereArgs;
  if (start != null && end != null) {
    where = 'dateTime BETWEEN ? AND ?';
    whereArgs = [start.toIso8601String(), end.toIso8601String()];
  }
  var res = await db.query('expenses', where: where, whereArgs: whereArgs, orderBy: 'dateTime DESC');
  return res.map((e) => Expense.fromMap(e)).toList();
}

Future<void> deleteMobileExpense(Database db, int id) async {
  await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
}

Future<void> deleteMobileTransaction(Database db, int id) async {
  await db.transaction((txn) async {
    await txn.delete('transaction_details', where: 'transactionId = ?', whereArgs: [id]);
    await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
  });
}
