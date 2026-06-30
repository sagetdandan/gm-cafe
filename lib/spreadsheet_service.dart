import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class SpreadsheetService {
  // URL ini nanti didapat dari "Deploy as Web App" di Google Apps Script
  static String? scriptUrl;

  Future<bool> checkConnection(String url) async {
    try {
      final response = await http.get(Uri.parse('$url?action=ping'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Category>> getCategories() async {
    if (scriptUrl == null) return [];
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getCategories'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Category(
          id: int.tryParse(item['id'].toString()),
          name: item['name'],
        )).toList();
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    return [];
  }

  Future<List<CafeTable>> getTables() async {
    if (scriptUrl == null) return [];
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getTables'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => CafeTable(
          id: int.tryParse(item['id'].toString()),
          number: item['number'].toString(),
          location: item['location'] ?? '',
          isOccupied: item['isOccupied'].toString() == '1',
        )).toList();
      }
    } catch (e) {
      print('Error fetching tables: $e');
    }
    return [];
  }

  Future<bool> initSheet(String url) async {
    try {
      final response = await http.get(Uri.parse('$url?action=initSheet'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Product>> getProducts() async {
    if (scriptUrl == null) return [];
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=getProducts'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Product(
          id: int.tryParse(item['id'].toString()),
          name: item['name'],
          price: double.tryParse(item['price'].toString()) ?? 0,
          hpp: double.tryParse(item['hpp'].toString()) ?? 0,
          priceBotol: double.tryParse(item['priceBotol'].toString()),
          hppBotol: double.tryParse(item['hppBotol'].toString()),
          categoryId: int.tryParse(item['categoryId'].toString()) ?? 0,
          imagePath: item['imageUrl'],
          barcode: item['barcode']?.toString(),
        )).toList();
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
    return [];
  }

  Future<bool> sendTransaction(TransactionHeader header, List<CartItem> items) async {
    if (scriptUrl == null) return false;
    try {
      final body = {
        'action': 'addTransaction',
        'date': header.dateTime.toIso8601String(),
        'total': header.totalAmount,
        'discount': header.discount,
        'method': header.paymentMethod,
        'items': jsonEncode(items.map((i) => {
          'name': i.product.name,
          'variant': i.variant,
          'qty': i.quantity,
          'price': i.unitPrice,
        }).toList()),
      };
      
      final response = await http.post(
        Uri.parse(scriptUrl!),
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending transaction: $e');
      return false;
    }
  }

  Future<bool> addProduct(Product p) async {
    if (scriptUrl == null) return false;
    try {
      final body = {
        'action': 'addProduct',
        'id': p.id?.toString() ?? '',
        'name': p.name,
        'price': p.price.toString(),
        'hpp': p.hpp.toString(),
        'priceBotol': (p.priceBotol ?? 0).toString(),
        'hppBotol': (p.hppBotol ?? 0).toString(),
        'categoryId': p.categoryId.toString(),
        'imageUrl': p.imagePath ?? '',
        'barcode': p.barcode ?? '',
      };
      final response = await http.post(Uri.parse(scriptUrl!), body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addCategory(String name) async {
    if (scriptUrl == null) return false;
    try {
      final body = {'action': 'addCategory', 'name': name};
      final response = await http.post(Uri.parse(scriptUrl!), body: body);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
