import 'models.dart';

Future<void> setupDatabaseFactory() async {}
Future<String> getDbPath(String name) async => name;
Future<dynamic> openMobileDatabase(String path, Function onCreate) async => null;
Future<List<Category>> getMobileCategories(dynamic db) async => [];
Future<List<CafeTable>> getMobileTables(dynamic db) async => [];
Future<void> insertMobileTable(dynamic db, CafeTable t) async {}
Future<void> updateMobileTable(dynamic db, CafeTable t) async {}
Future<void> deleteMobileTable(dynamic db, int id) async {}
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
