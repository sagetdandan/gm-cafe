import 'package:flutter/foundation.dart' show kIsWeb;
import 'models.dart';
import 'db_setup_stub.dart' if (dart.library.io) 'db_setup_mobile.dart';

// Definisi tipe data dummy agar tidak tergantung sqflite di Web
abstract class AppDatabase {}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static dynamic _database;

  Future<dynamic> get database async {
    if (_database != null) return _database!;
    if (kIsWeb) return null;
    
    await setupDatabaseFactory();
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<dynamic> _initDatabase() async {
    if (kIsWeb) return null;
    String path = 'gm_cafe_v1.db';
    path = await getDbPath('gm_cafe_v1.db');

    // Kita gunakan dynamic untuk menghindari import sqflite di file ini
    // Pemanggilan fungsi sqflite dilakukan di db_setup_mobile
    return await openMobileDatabase(path, _onCreate);
  }

  Future _onCreate(dynamic db, int version) async {
    // Kosong karena logic pemindahan ke mobile setup
  }

  Future<List<Category>> getCategories() async {
    if (kIsWeb) return [];
    // Pemanggilan ke mobile helper
    return await getMobileCategories(await database);
  }

  Future<void> insertCategory(Category category) async {
    if (kIsWeb) return;
    await insertMobileCategory(await database, category);
  }

  Future<List<CafeTable>> getTables() async {
    if (kIsWeb) return [];
    return await getMobileTables(await database);
  }

  Future<void> insertTable(CafeTable table) async {
    if (kIsWeb) return;
    await insertMobileTable(await database, table);
  }

  Future<void> updateTable(CafeTable table) async {
    if (kIsWeb) return;
    await updateMobileTable(await database, table);
  }

  Future<void> deleteTable(int id) async {
    if (kIsWeb) return;
    await deleteMobileTable(await database, id);
  }

  Future<List<AppUser>> getUsers() async {
    if (kIsWeb) return [];
    return await getMobileUsers(await database);
  }

  Future<void> insertUser(AppUser user) async {
    if (kIsWeb) return;
    await insertMobileUser(await database, user);
  }

  Future<void> updateUser(AppUser user) async {
    if (kIsWeb) return;
    await updateMobileUser(await database, user);
  }

  Future<void> deleteUser(int id) async {
    if (kIsWeb) return;
    await deleteMobileUser(await database, id);
  }

  Future<AppUser?> login(String username, String password) async {
    if (kIsWeb) {
      // Logic login web sederhana karena kIsWeb null database
      if (username == 'admin' && password == '123') {
        return AppUser(username: 'admin', password: '123', name: 'Web Admin', role: 'admin');
      }
      if (username == 'kasir' && password == '123') {
        return AppUser(username: 'kasir', password: '123', name: 'Web Kasir', role: 'cashier');
      }
      return null;
    }
    return await loginMobile(await database, username, password);
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    if (kIsWeb) return [];
    return await getMobileProductsByCategory(await database, categoryId);
  }

  Future<List<Product>> getAllProducts() async {
    if (kIsWeb) return [];
    return await getMobileAllProducts(await database);
  }

  Future<void> insertProduct(Product product) async {
    if (kIsWeb) return;
    await insertMobileProduct(await database, product);
  }

  Future<void> updateProduct(Product product) async {
    if (kIsWeb) return;
    await updateMobileProduct(await database, product);
  }

  Future<void> insertTransaction(TransactionHeader header, List<CartItem> items) async {
    if (kIsWeb) return;
    await insertMobileTransaction(await database, header, items);
  }

  Future<List<TransactionHeader>> getTransactions({DateTime? start, DateTime? end}) async {
    if (kIsWeb) return [];
    return await getMobileTransactions(await database, start, end);
  }

  Future<List<Map<String, dynamic>>> getTransactionDetails(int transactionId) async {
    if (kIsWeb) return [];
    return await getMobileTransactionDetails(await database, transactionId);
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) return 0;
    return await insertMobileExpense(await database, expense);
  }

  Future<List<Expense>> getExpenses({DateTime? start, DateTime? end}) async {
    if (kIsWeb) return [];
    return await getMobileExpenses(await database, start, end);
  }

  Future<void> deleteExpense(int id) async {
    if (kIsWeb) return;
    await deleteMobileExpense(await database, id);
  }

  Future<void> deleteTransaction(int id) async {
    if (kIsWeb) return;
    await deleteMobileTransaction(await database, id);
  }
}

// Stub functions yang akan diimplementasikan di mobile
Future<dynamic> openMobileDatabase(String path, Function onCreate) async => null;
Future<List<Category>> getMobileCategories(dynamic db) async => [];
Future<void> insertMobileCategory(dynamic db, Category c) async {}
Future<List<CafeTable>> getMobileTables(dynamic db) async => [];
Future<void> insertMobileTable(dynamic db, CafeTable t) async {}
Future<void> updateMobileTable(dynamic db, CafeTable t) async {}
Future<void> deleteMobileTable(dynamic db, int id) async {}
Future<List<AppUser>> getMobileUsers(dynamic db) async => [];
Future<void> insertMobileUser(dynamic db, AppUser u) async {}
Future<void> updateMobileUser(dynamic db, AppUser u) async {}
Future<void> deleteMobileUser(dynamic db, int id) async {}
Future<AppUser?> loginMobile(dynamic db, String u, String p) async => null;
Future<List<Product>> getMobileProductsByCategory(dynamic db, int id) async => [];
Future<List<Product>> getMobileAllProducts(dynamic db) async => [];
Future<void> insertMobileProduct(dynamic db, Product p) async {}
Future<void> updateMobileProduct(dynamic db, Product p) async {}
Future<void> insertMobileTransaction(dynamic db, TransactionHeader h, List<CartItem> i) async {}
Future<List<TransactionHeader>> getMobileTransactions(dynamic db, DateTime? s, DateTime? e) async => [];
Future<List<Map<String, dynamic>>> getMobileTransactionDetails(dynamic db, int id) async => [];
Future<int> insertMobileExpense(dynamic db, Expense e) async => 0;
Future<List<Expense>> getMobileExpenses(dynamic db, DateTime? s, DateTime? e) async => [];
Future<void> deleteMobileExpense(dynamic db, int id) async {}
Future<void> deleteMobileTransaction(dynamic db, int id) async {}
