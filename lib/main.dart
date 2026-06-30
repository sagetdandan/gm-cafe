import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'database_helper.dart';
import 'models.dart';
import 'printer_service.dart';
import 'spreadsheet_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi database desktop dipindah ke dalam DatabaseHelper agar web aman
  runApp(const GadungmelatiApp());
}

class GadungmelatiApp extends StatelessWidget {
  const GadungmelatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GADUNGMELATI KASIR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: kIsWeb ? Brightness.light : Brightness.dark,
          primary: const Color(0xFFD4AF37),
          surface: kIsWeb ? Colors.white : const Color(0xFF121212),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: kIsWeb ? Colors.blue[50] : const Color(0xFF121212),
        textTheme: kIsWeb ? const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodyLarge: TextStyle(color: Colors.black),
        ) : null,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('ss_url');
    if (url != null && url.isNotEmpty) {
      SpreadsheetService.scriptUrl = url;
      try {
        await SpreadsheetService().getCategories();
        await SpreadsheetService().getProducts();
        await SpreadsheetService().getTables();
      } catch (e) {
        debugPrint("Error pulling data: $e");
      }
    }
    
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kIsWeb ? Colors.white : const Color(0xFF000000), // Pure black matching logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/logo_gm_cafe.png'),
              height: 250,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFFD4AF37)),
            const SizedBox(height: 10),
            Text(
              "Menarik data...",
              style: TextStyle(color: kIsWeb ? Colors.black : const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kIsWeb ? Colors.blue[50] : const Color(0xFF121212),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        const Image(
                          image: AssetImage('assets/logo_gm_cafe.png'),
                          height: 180,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 250,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CashierPage())),
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('MASUK KASIR', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 250,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: () => _showAdminLogin(context),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('ADMIN PANEL', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                              foregroundColor: const Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text('support by @sagetdandan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAdminLogin(BuildContext context) {
    final controller = TextEditingController();

    Future<void> login() async {
      final prefs = await SharedPreferences.getInstance();
      final savedPass = prefs.getString('admin_pass') ?? '1234';
      if (controller.text == savedPass) {
        if (context.mounted) {
          Navigator.pop(context);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const AdminPage()));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Password Salah!')));
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Admin'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password', hintText: 'Default: 1234'),
          onSubmitted: (_) => login(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: login,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class CashierPage extends StatelessWidget {
  const CashierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CashierScaffold();
  }
}

class CashierScaffold extends StatefulWidget {
  const CashierScaffold({super.key});

  @override
  State<CashierScaffold> createState() => _CashierScaffoldState();
}

class _CashierScaffoldState extends State<CashierScaffold> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SpreadsheetService _ssService = SpreadsheetService();
  
  List<Category> _mainCategories = [];
  List<Product> _products = [];
  List<CafeTable> _tables = [];
  
  CafeTable? _selectedTable;
  Category? _selectedCategory;
  AppBluetoothDevice? _selectedPrinter;
  bool _isCloudSync = false;
  bool _showingTables = true;
  
  final List<CartItem> _cart = [];
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadInitialData();
    _loadPrinter();
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('ss_url');
    SpreadsheetService.scriptUrl = url;
    _isCloudSync = url != null && url.isNotEmpty;

    // Patenkan kategori
    List<Category> cats = [
      Category(id: 1, name: 'COFFEE'),
      Category(id: 2, name: 'NON COFFEE'),
      Category(id: 3, name: 'SNACK'),
    ];
    
    List<CafeTable> tables = [];
    
    if (_isCloudSync) {
      tables = await _ssService.getTables();
    }
    
    if (tables.isEmpty) {
      tables = await _dbHelper.getTables();
    }

    setState(() {
      _mainCategories = cats;
      _tables = tables;
      if (_mainCategories.isNotEmpty) {
        _selectCategory(_mainCategories.first);
      }
    });
  }

  void _showPrinterSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Setting Printer'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<AppBluetoothDevice>(
                    isExpanded: true,
                    hint: const Text('Pilih Printer'),
                    value: _selectedPrinter,
                    onChanged: (d) async {
                      if (d != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selected_printer', jsonEncode({'name': d.name, 'address': d.address}));
                        setState(() => _selectedPrinter = d);
                        setDialogState(() {});
                      }
                    },
                    items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? ''))).toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final devices = await PrinterService().getDevices();
                      setState(() => _devices = devices);
                      setDialogState(() {});
                    },
                    child: const Text('Scan Printer'),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
          );
        },
      ),
    );
  }

  List<AppBluetoothDevice> _devices = [];
  Future<void> _loadPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final printerJson = prefs.getString('selected_printer');
    if (printerJson != null) {
      final map = jsonDecode(printerJson);
      setState(() {
        _selectedPrinter = AppBluetoothDevice(map['name'], map['address']);
      });
    }
    _devices = await PrinterService().getDevices();
  }

  Future<void> _selectCategory(Category category) async {
    List<Product> products = [];
    if (_isCloudSync) {
      final all = await _ssService.getProducts();
      products = all.where((p) => p.categoryId == category.id).toList();
    } else {
      products = await _dbHelper.getProductsByCategory(category.id!);
    }
    
    setState(() {
      _selectedCategory = category;
      _products = products;
    });
  }

  void _onBarcodeScanned(String code) async {
    if (code.isEmpty) return;
    
    List<Product> allProducts = [];
    if (_isCloudSync) {
      allProducts = await _ssService.getProducts();
    } else {
      allProducts = await _dbHelper.getAllProducts();
    }

    try {
      final product = allProducts.firstWhere((p) => p.barcode == code);
      _showVariantSelection(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk dengan barcode $code tidak ditemukan')),
        );
      }
    }
  }

  void _showBarcodeScanner() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Barcode Menu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Input barcode...',
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          onSubmitted: (val) {
            Navigator.pop(context);
            _onBarcodeScanned(val);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onBarcodeScanned(controller.text);
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product, {String variant = "Hot"}) {
    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id && item.variant == variant);
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(CartItem(product: product, variant: variant));
      }
    });
  }

  void _showVariantSelection(Product product) {
    if (product.priceBotol != null && product.priceBotol! > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Pilih Tipe: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('HOT'),
                trailing: Text(currencyFormat.format(product.price)),
                onTap: () {
                  _addToCart(product, variant: "Hot");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('ICE'),
                trailing: Text(currencyFormat.format(product.priceBotol!)),
                onTap: () {
                  _addToCart(product, variant: "Ice");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      _addToCart(product);
    }
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cart.remove(item);
      }
    });
  }

  double get _totalPrice => _cart.fold(0, (sum, item) => sum + item.totalPrice);


  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        total: _totalPrice,
        cartItems: List.from(_cart),
        selectedPrinter: _selectedPrinter,
        onPaymentSuccess: (method, discount) async {
          final transaction = TransactionHeader(
            dateTime: DateTime.now(),
            totalAmount: _totalPrice - discount,
            discount: discount,
            paymentMethod: method,
          );
          
          if (_isCloudSync) {
            await _ssService.sendTransaction(transaction, List.from(_cart));
          } else {
            await _dbHelper.insertTransaction(transaction, List.from(_cart));
          }

          setState(() {
            _cart.clear();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pembayaran dengan $method Berhasil!')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showingTables ? 'Dashboard Meja' : 'Pilih Menu - ${_selectedTable?.number}', style: TextStyle(fontWeight: FontWeight.bold, color: kIsWeb ? Colors.black : const Color(0xFFD4AF37))),
        leading: _showingTables ? IconButton(
          icon: Icon(Icons.logout, color: kIsWeb ? Colors.black : Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
        ) : IconButton(
          icon: Icon(Icons.arrow_back, color: kIsWeb ? Colors.black : Colors.white),
          onPressed: () => setState(() => _showingTables = true),
        ),
        actions: [
          if (!_showingTables) ...[
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: kIsWeb ? Colors.black : const Color(0xFFD4AF37)),
              onPressed: _showBarcodeScanner,
              tooltip: 'Scan Menu',
            ),
          ],
          IconButton(
            icon: Icon(Icons.print, color: kIsWeb ? Colors.black : Colors.white),
            onPressed: () => _showPrinterSettings(),
            tooltip: 'Pengaturan',
          )
        ],
        backgroundColor: kIsWeb ? Colors.blue[100] : const Color(0xFF1E1E1E),
        elevation: 2,
      ),
      body: _showingTables ? _buildTableDashboard() : _buildCashierMain(),
    );
  }

  Widget _buildTableDashboard() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
      ),
      itemCount: _tables.length,
      itemBuilder: (context, index) {
        final table = _tables[index];
        return Card(
          color: table.isOccupied ? Colors.red[300] : (kIsWeb ? Colors.white : const Color(0xFF1E1E1E)),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFFD4AF37), width: 1)),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTable = table;
                _showingTables = false;
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('MEJA', style: TextStyle(fontSize: 14, color: kIsWeb ? Colors.black54 : Colors.white54)),
                Text(table.number, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kIsWeb ? Colors.black : const Color(0xFFD4AF37))),
                if (table.location.isNotEmpty)
                  Text(table.location, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashierMain() {
    return Row(
      children: [
        // Sidebar Main Categories
        Container(
          width: 180,
          decoration: BoxDecoration(
            color: kIsWeb ? Colors.blue[200] : const Color(0xFF1A1A1A),
            border: Border(right: BorderSide(color: kIsWeb ? Colors.blue[300]! : Colors.white10)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Image(
                  image: AssetImage('assets/logo_gm_cafe.png'),
                  height: 80,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var cat in _mainCategories)
                        InkWell(
                          onTap: () => _selectCategory(cat),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _selectedCategory?.id == cat.id ? Colors.blue[100] : Colors.transparent,
                              border: const Border(bottom: BorderSide(color: Colors.white10)),
                            ),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedCategory?.id == cat.id ? FontWeight.bold : FontWeight.w600,
                                color: _selectedCategory?.id == cat.id ? Colors.black : (kIsWeb ? Colors.black87 : Colors.white70),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'supported by @sagetdandan',
                  style: TextStyle(fontSize: 10, color: kIsWeb ? Colors.black54 : const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // Product Grid Area
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedCategory?.name ?? '',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kIsWeb ? Colors.blue[900] : const Color(0xFFD4AF37)),
                ),
              ),
              Divider(height: 1, color: kIsWeb ? Colors.blue[200] : Colors.white10),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      elevation: 4,
                      color: kIsWeb ? Colors.white : const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        onTap: () => _showVariantSelection(product),
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: kIsWeb ? Colors.blue[50] : Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: product.imagePath != null
                                      ? (product.imagePath!.startsWith('http') 
                                          ? Image.network(product.imagePath!, fit: BoxFit.cover, width: 80, height: 80)
                                          : (kIsWeb 
                                              ? Image.network(product.imagePath!, fit: BoxFit.cover, width: 80, height: 80)
                                              : Image.file(File(product.imagePath!), fit: BoxFit.cover, width: 80, height: 80)))
                                      : Icon(
                                          Icons.coffee,
                                          size: 40,
                                          color: kIsWeb ? Colors.blue[300] : const Color(0xFFD4AF37),
                                        ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kIsWeb ? Colors.black : Colors.white),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currencyFormat.format(product.price),
                                      style: TextStyle(color: kIsWeb ? Colors.blue[700] : const Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Cart Summary
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: kIsWeb ? Colors.white : const Color(0xFF161616),
            border: Border(left: BorderSide(color: kIsWeb ? Colors.blue[200]! : Colors.white10)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                color: kIsWeb ? Colors.blue[50] : const Color(0xFF1E1E1E),
                child: Text('Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kIsWeb ? Colors.black : const Color(0xFFD4AF37))),
              ),
              Expanded(
                child: _cart.isEmpty
                    ? Center(child: Text('Keranjang kosong', style: TextStyle(color: kIsWeb ? Colors.black38 : Colors.white38)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _cart.length,
                        separatorBuilder: (_, __) => Divider(color: kIsWeb ? Colors.blue[100] : Colors.white10),
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return ListTile(
                            dense: true,
                            title: Text('${item.product.name} (${item.variant})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kIsWeb ? Colors.black : Colors.white)),
                            subtitle: Row(
                              children: [
                                IconButton(icon: Icon(Icons.remove_circle, size: 18, color: kIsWeb ? Colors.blue : const Color(0xFFD4AF37)), onPressed: () => _removeFromCart(item)),
                                Text('${item.quantity}', style: TextStyle(fontSize: 14, color: kIsWeb ? Colors.black : Colors.white)),
                                IconButton(icon: Icon(Icons.add_circle, size: 18, color: kIsWeb ? Colors.blue : const Color(0xFFD4AF37)), onPressed: () => _addToCart(item.product, variant: item.variant)),
                              ],
                            ),
                            trailing: Text(currencyFormat.format(item.totalPrice), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kIsWeb ? Colors.blue[900] : const Color(0xFFD4AF37))),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: kIsWeb ? Colors.blue[50] : const Color(0xFF1E1E1E),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 16, color: kIsWeb ? Colors.black : Colors.white)),
                        Text(currencyFormat.format(_totalPrice), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kIsWeb ? Colors.blue[900] : const Color(0xFFD4AF37))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _cart.isEmpty ? null : _showPaymentDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kIsWeb ? Colors.blue : const Color(0xFFD4AF37), 
                          foregroundColor: kIsWeb ? Colors.white : Colors.black
                        ),
                        child: const Text('BAYAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PaymentDialog extends StatefulWidget {
  final double total;
  final List<CartItem> cartItems;
  final AppBluetoothDevice? selectedPrinter;
  final Function(String method, double discount) onPaymentSuccess;

  const PaymentDialog({
    super.key,
    required this.total,
    required this.cartItems,
    this.selectedPrinter,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String? _paymentMethod;
  String? _qrisImagePath;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  double _cashReceived = 0;
  double _discount = 0;
  double _change = 0;
  bool _isFinished = false;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadQris();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadQris() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _qrisImagePath = prefs.getString('qris_path'));
  }

  double get _finalTotal => widget.total - _discount;

  void _calculateChange(String value) {
    setState(() {
      _cashReceived = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      _change = _cashReceived - _finalTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          if (_isFinished) {
            // Jika sudah selesai, Enter = Transaksi Baru
            widget.onPaymentSuccess(_paymentMethod!, _discount);
            Navigator.pop(context);
          } else if (_paymentMethod == 'Tunai' && _change >= 0) {
            setState(() => _isFinished = true);
          } else if (_paymentMethod == 'QRIS') {
            setState(() => _isFinished = true);
          }
        }
      },
      child: AlertDialog(
        title: Text(_isFinished ? 'Selesai' : 'Pilih Pembayaran'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      content: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isFinished) ...[
                Text('Subtotal: ${currencyFormat.format(widget.total)}', style: const TextStyle(fontSize: 16)),
                TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Diskon (%)', suffixText: '%'),
                  onChanged: (val) {
                    setState(() {
                      double pct = double.tryParse(val) ?? 0;
                      _discount = (pct / 100) * widget.total;
                      if (_cashController.text.isNotEmpty) {
                        _calculateChange(_cashController.text);
                      }
                    });
                  },
                ),
                if (_discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Potongan: -${currencyFormat.format(_discount)}', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 8),
                Text('Total: ${currencyFormat.format(_finalTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.brown)),
                const SizedBox(height: 16),
                if (_paymentMethod == null) ...[
                  ListTile(
                    leading: const Icon(Icons.money, color: Colors.green),
                    title: const Text('Tunai', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => setState(() => _paymentMethod = 'Tunai'),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.qr_code, color: Colors.blue),
                    title: const Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => setState(() => _paymentMethod = 'QRIS'),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  ),
                ] else if (_paymentMethod == 'Tunai') ...[
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Uang Diterima', prefixText: 'Rp ', border: OutlineInputBorder()),
                    onChanged: _calculateChange,
                    onSubmitted: (_) {
                      if (_change >= 0) setState(() => _isFinished = true);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembalian:', style: TextStyle(fontSize: 16)),
                      Text(currencyFormat.format(_change > 0 ? _change : 0),
                          style: TextStyle(color: _change >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _paymentMethod = null), child: const Text('Kembali'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _change < 0 ? null : () => setState(() => _isFinished = true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                          child: const Text('SELESAI'),
                        ),
                      ),
                    ],
                  ),
                ] else if (_paymentMethod == 'QRIS') ...[
                  _qrisImagePath != null && !kIsWeb
                      ? const Icon(Icons.qr_code, size: 220)
                      : QrImageView(data: 'GM-Payment-$_finalTotal', version: QrVersions.auto, size: 220.0),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _paymentMethod = null), child: const Text('Kembali'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isFinished = true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text('SUDAH BAYAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 10),
                const Text('Pembayaran Berhasil!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      ...widget.cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${item.product.name} (${item.variant}) x${item.quantity}', style: const TextStyle(fontSize: 12))),
                            Text(currencyFormat.format(item.totalPrice), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )),
                      const Divider(),
                      if (_discount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diskon', style: TextStyle(fontSize: 12)),
                            Text('-${currencyFormat.format(_discount)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(currencyFormat.format(_finalTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (_paymentMethod == 'Tunai') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bayar', style: TextStyle(fontSize: 12)),
                            Text(currencyFormat.format(_cashReceived), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembali', style: TextStyle(fontSize: 12)),
                            Text(currencyFormat.format(_change > 0 ? _change : 0), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (widget.selectedPrinter != null) {
                        await PrinterService().printReceipt(
                          device: widget.selectedPrinter!,
                          items: widget.cartItems,
                          total: _finalTotal,
                          discount: _discount,
                          cash: _paymentMethod == 'Tunai' ? _cashReceived : _finalTotal,
                          change: _paymentMethod == 'Tunai' ? (_change > 0 ? _change : 0) : 0,
                          paymentMethod: _paymentMethod!,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer belum diset!')));
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('CETAK STRUK'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onPaymentSuccess(_paymentMethod!, _discount);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        child: const Text('TRANSAKSI BARU'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!_isFinished && _paymentMethod == null)
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      ],
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PrinterService _printerService = PrinterService();
  final SpreadsheetService _ssService = SpreadsheetService();
  bool _isCloudSync = false;

  List<Category> _mainCategories = [];
  List<Product> _products = [];
  List<CafeTable> _tables = [];
  Category? _selectedCategory;

  String? _qrisPath;
  String? _shopLogoPath;
  String _paperSize = '58mm';
  
  late TextEditingController _addressController;
  late TextEditingController _footerController;
  
  late TextEditingController _ssUrlController;
  
  String _shopAddress = 'Jl. Contoh No. 123';
  String _shopFooter = 'Terima Kasih Atas Kunjungan Anda';
  List<AppBluetoothDevice> _devices = [];
  AppBluetoothDevice? _selectedDevice;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59),
  );
  List<TransactionHeader> _reports = [];
  List<Expense> _expenses = [];
  double _totalHpp = 0;
  final _picker = ImagePicker();
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _footerController = TextEditingController();
    _ssUrlController = TextEditingController();
    _loadInitialData();
    _loadData();
    _getBluetoothDevices();
    _loadReports();
    _loadExpenses();
    _loadTables();
  }

  Future<void> _loadTables() async {
    final res = await _dbHelper.getTables();
    setState(() => _tables = res);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _footerController.dispose();
    _ssUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown, primary: Colors.brown),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _loadReports();
      _loadExpenses();
    }
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Laporan'];

      sheet.appendRow([TextCellValue('Laporan Keuangan Gadungmelati Cafe')]);
      sheet.appendRow([TextCellValue('Periode: ${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}')]);
      sheet.appendRow([]);

      sheet.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Tipe'),
        TextCellValue('Keterangan'),
        TextCellValue('Metode'),
        TextCellValue('Nominal'),
      ]);

      for (var r in _reports) {
        sheet.appendRow([
          TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(r.dateTime)),
          TextCellValue('Penjualan'),
          TextCellValue('-'),
          TextCellValue(r.paymentMethod),
          DoubleCellValue(r.totalAmount),
        ]);
      }

      for (var e in _expenses) {
        sheet.appendRow([
          TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(e.dateTime)),
          TextCellValue('Pengeluaran'),
          TextCellValue(e.description),
          TextCellValue('-'),
          DoubleCellValue(-e.amount),
        ]);
      }

      var fileBytes = excel.save();
      if (kIsWeb) {
        // Pada web, kita bisa menggunakan download link atau log saja
        print('Export Excel berhasil (bytes length: ${fileBytes?.length})');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ekspor Excel di Web hanya simulasi (cek console)')));
        return;
      }
      
      // Menggunakan dart:io secara aman hanya untuk non-web
      // Kita panggil melalui helper jika perlu, tapi di sini kita pakai XFile
      // sebenarnya XFile dari share_plus bisa menangani byte
      
      final xFile = XFile.fromData(
        Uint8List.fromList(fileBytes!),
        name: 'Laporan_GM.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await Share.shareXFiles([xFile], text: 'Laporan Gadungmelati Cafe');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
      }
    }
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('ss_url');
    SpreadsheetService.scriptUrl = url;
    _isCloudSync = url != null && url.isNotEmpty;

    // Patenkan kategori
    List<Category> cats = [
      Category(id: 1, name: 'COFFEE'),
      Category(id: 2, name: 'NON COFFEE'),
      Category(id: 3, name: 'SNACK'),
    ];
    
    List<CafeTable> tables = [];
    
    if (_isCloudSync) {
      tables = await _ssService.getTables();
    }
    
    if (tables.isEmpty) {
      tables = await _dbHelper.getTables();
    }

    setState(() {
      _mainCategories = cats;
      _tables = tables;
      if (_mainCategories.isNotEmpty) {
        _selectCategory(_mainCategories.first);
      }
    });
  }

  Future<void> _selectCategory(Category category) async {
    List<Product> products = [];
    if (_isCloudSync) {
      final all = await _ssService.getProducts();
      products = all.where((p) => p.categoryId == category.id).toList();
    } else {
      products = await _dbHelper.getProductsByCategory(category.id!);
    }

    setState(() {
      _selectedCategory = category;
      _products = products;
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final printerJson = prefs.getString('selected_printer');
    setState(() {
      _qrisPath = prefs.getString('qris_path');
      _shopLogoPath = prefs.getString('shop_logo_path');
      _paperSize = prefs.getString('paper_size') ?? '58mm';
      _shopAddress = prefs.getString('shop_address') ?? 'Jl. Contoh No. 123';
      _shopFooter = prefs.getString('shop_footer') ?? 'Terima Kasih Atas Kunjungan Anda';
      _addressController.text = _shopAddress;
      _footerController.text = _shopFooter;
      _ssUrlController.text = prefs.getString('ss_url') ?? 'https://script.google.com/macros/s/AKfycbwjkVAWV43mqQrA6pu6k6O8E8MZqJ6t0e1qu5jWkQx-mAiWksMLmbC5Im1twsyM7D51ng/exec';
      if (printerJson != null) {
        final map = jsonDecode(printerJson);
        _selectedDevice = AppBluetoothDevice(map['name'], map['address']);
      }
    });
  }

  Future<void> _getBluetoothDevices() async {
    final devices = await _printerService.getDevices();
    setState(() => _devices = devices);
  }

  Future<void> _loadReports() async {
    final res = await _dbHelper.getTransactions(start: _dateRange.start, end: _dateRange.end);
    double hppSum = 0;
    for (var r in res) {
      final details = await _dbHelper.getTransactionDetails(r.id!);
      for (var d in details) {
        hppSum += (d['hpp'] ?? 0) * (d['quantity'] ?? 1);
      }
    }
    setState(() {
      _reports = res;
      _totalHpp = hppSum;
    });
  }

  Future<void> _loadExpenses() async {
    final res = await _dbHelper.getExpenses(start: _dateRange.start, end: _dateRange.end);
    setState(() => _expenses = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gadungmelati Cafe - ADMIN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
      ),
      body: Row(
        children: [
          // Admin Sidebar (Merged with Categories)
          Container(
            width: 190,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(right: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: const Image(
                    image: AssetImage('assets/logo_gm_cafe.png'),
                    height: 80,
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                          child: const Text('KATEGORI MENU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white38)),
                        ),
                        if (_mainCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Memuat...', style: TextStyle(fontSize: 10, color: Colors.white24)),
                          ),
                        for (var cat in _mainCategories)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = 0;
                                _selectedCategory = cat;
                              });
                              _selectCategory(cat);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: (_selectedIndex == 0 && _selectedCategory?.id == cat.id) ? Colors.blue[100] : Colors.transparent,
                                border: const Border(bottom: BorderSide(color: Colors.white10)),
                              ),
                              child: Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: (_selectedIndex == 0 && _selectedCategory?.id == cat.id) ? FontWeight.bold : FontWeight.w600,
                                  color: (_selectedIndex == 0 && _selectedCategory?.id == cat.id) ? Colors.black : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        const Divider(height: 1, color: Colors.white10),
                        _adminMenuItem(1, Icons.payments, 'Pengeluaran'),
                        _adminMenuItem(2, Icons.receipt_long, 'Laporan'),
                        _adminMenuItem(5, Icons.table_restaurant, 'Meja'),
                        _adminMenuItem(3, Icons.settings, 'Pengaturan'),
                        _adminMenuItem(4, Icons.logout, 'Exit', color: Colors.redAccent),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'supported by @sagetdandan',
                    style: TextStyle(fontSize: 10, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex == 5 ? 4 : _selectedIndex,
              children: [
                _buildMenuTabGrid(),
                _buildExpenseTab(),
                _buildReportTab(),
                _buildSettingTab(),
                _buildTableTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminMenuItem(int index, IconData icon, String title, {Color? color}) {
    if (index == 4) { // Special case for Exit
      return ListTile(
        dense: true,
        leading: Icon(icon, color: color ?? const Color(0xFFD4AF37)),
        title: Text(title, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.white70,
        )),
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
      );
    }
    
    final isSelected = _selectedIndex == index;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: Colors.blue[100],
      leading: Icon(icon, color: isSelected ? Colors.black : (color ?? const Color(0xFFD4AF37))),
      title: Text(title, style: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? Colors.black : (color ?? Colors.white),
      )),
      onTap: () => setState(() {
        _selectedIndex = index;
        if (index != 0) _selectedCategory = null;
      }),
    );
  }

  Widget _buildSettingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButton<AppBluetoothDevice>(
          isExpanded: true,
          hint: const Text('Pilih Printer'),
          value: _devices.any((d) => d.address == _selectedDevice?.address) 
              ? _devices.firstWhere((d) => d.address == _selectedDevice?.address) : null,
          onChanged: (d) async {
            if (d != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('selected_printer', jsonEncode({'name': d.name, 'address': d.address}));
              setState(() => _selectedDevice = d);
            }
          },
          items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? ''))).toList(),
        ),
        ElevatedButton(onPressed: _getBluetoothDevices, child: const Text('Scan Printer')),
        const SizedBox(height: 16),
        const Text('Ukuran Kertas', style: TextStyle(fontWeight: FontWeight.bold)),
        Column(
          children: [
            RadioListTile<String>(
              title: const Text('58mm'),
              value: '58mm',
              groupValue: _paperSize,
              onChanged: (val) async {
                if (val != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('paper_size', val);
                  setState(() => _paperSize = val);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('80mm'),
              value: '80mm',
              groupValue: _paperSize,
              onChanged: (val) async {
                if (val != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('paper_size', val);
                  setState(() => _paperSize = val);
                }
              },
            ),
          ],
        ),
        const Divider(height: 40),
        const Text('Informasi Nota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ListTile(
          leading: _shopLogoPath != null && !kIsWeb ? const Icon(Icons.image) : const Icon(Icons.image),
          title: const Text('Upload Logo Header Struk'),
          onTap: () async {
            final x = await _picker.pickImage(source: ImageSource.gallery);
            if (x != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('shop_logo_path', x.path);
              setState(() => _shopLogoPath = x.path);
            }
          },
        ),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Alamat Toko', hintText: 'Jl. Contoh No. 123'),
          onChanged: (val) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('shop_address', val);
            _shopAddress = val;
          },
        ),
        TextField(
          controller: _footerController,
          decoration: const InputDecoration(labelText: 'Pesan Kaki (Footer)', hintText: 'Terima Kasih Atas Kunjungan Anda'),
          onChanged: (val) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('shop_footer', val);
            _shopFooter = val;
          },
        ),
        const Divider(height: 40),
        const Text('QRIS Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ListTile(
          leading: _qrisPath != null && !kIsWeb ? const Icon(Icons.qr_code) : const Icon(Icons.qr_code),
          title: const Text('Upload Gambar QRIS'),
          onTap: () async {
            final x = await _picker.pickImage(source: ImageSource.gallery);
            if (x != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('qris_path', x.path);
              setState(() => _qrisPath = x.path);
            }
          },
        ),
        TextField(
          controller: _ssUrlController,
          decoration: InputDecoration(
            labelText: 'Google Spreadsheet Script URL', 
            hintText: 'https://script.google.com/macros/s/.../exec',
            helperText: 'Digunakan untuk sinkronisasi menu & laporan online',
            suffixIcon: IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Inisialisasi Kolom Spreadsheet',
              onPressed: () async {
                if (_ssUrlController.text.isEmpty) return;
                bool ok = await SpreadsheetService().initSheet(_ssUrlController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Berhasil Inisialisasi!' : 'Gagal terhubung ke Script URL')),
                  );
                }
              },
            ),
          ),
          onChanged: (val) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ss_url', val);
          },
        ),
        const Divider(height: 40),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Ganti Password Admin'),
          onTap: () {
            final c = TextEditingController();
            showDialog(context: context, builder: (context) => AlertDialog(
              title: const Text('Password Baru'),
              content: TextField(controller: c, obscureText: true),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                TextButton(onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('admin_pass', c.text);
                  if (mounted) Navigator.pop(context);
                }, child: const Text('Simpan')),
              ],
            ));
          },
        ),
      ],
    );
  }

  Widget _buildMenuTabGrid() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
          child: Text(
            'Edit Menu: ${_selectedCategory?.name ?? ""}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _products.length + 1,
            itemBuilder: (context, index) {
              if (index == _products.length) {
                return Card(
                  elevation: 0,
                  color: Colors.brown[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.brown[300]!, width: 2),
                  ),
                  child: InkWell(
                    onTap: _showAddProductDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 50, color: Colors.brown),
                        SizedBox(height: 8),
                        Text('Tambah Menu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                      ],
                    ),
                  ),
                );
              }

              final p = _products[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: InkWell(
                  onTap: () {
                    final cPrice = TextEditingController(text: p.price.toString());
                    final cPriceBotol = TextEditingController(text: (p.priceBotol ?? 0).toString());
                    final cHppBotol = TextEditingController(text: (p.hppBotol ?? 0).toString());
                    String? selectedImagePath = p.imagePath;
                    List<Map<String, TextEditingController>> hppControllers = [];
                    
                    if (p.hppDetails != null && p.hppDetails!.isNotEmpty) {
                      try {
                        List<dynamic> decoded = jsonDecode(p.hppDetails!);
                        for (var item in decoded) {
                          hppControllers.add({
                            'desc': TextEditingController(text: item['desc'].toString()),
                            'cost': TextEditingController(text: item['cost'].toString())
                          });
                        }
                      } catch (e) {
                        hppControllers = [{'desc': TextEditingController(), 'cost': TextEditingController(text: p.hpp.toString())}];
                      }
                    } else {
                      hppControllers = [{'desc': TextEditingController(), 'cost': TextEditingController(text: p.hpp.toString())}];
                    }

                    showDialog(context: context, builder: (context) => StatefulBuilder(
                      builder: (context, setDialogState) {
                        double totalHpp = hppControllers.fold(0, (sum, item) {
                          double val = double.tryParse(item['cost']!.text) ?? 0;
                          return sum + val;
                        });

                        return AlertDialog(
                          title: Text('Edit ${p.name}'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final x = await _picker.pickImage(source: ImageSource.gallery);
                                    if (x != null) {
                                      setDialogState(() => selectedImagePath = x.path);
                                    }
                                  },
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.brown[50],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.brown[200]!),
                                    ),
                                    child: selectedImagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: kIsWeb
                                                ? Image.network(selectedImagePath!, fit: BoxFit.cover)
                                                : Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, color: Colors.brown),
                                              Text('Ubah Foto', style: TextStyle(fontSize: 10, color: Colors.brown)),
                                            ],
                                          ),
                                  ),
                                ),
                                TextField(controller: cPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual (HOT)')),
                                TextField(controller: cPriceBotol, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual (ICE) - Isi 0 jika tdk ada')),
                                TextField(controller: cHppBotol, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'HPP (ICE) - Isi 0 jika tdk ada')),
                                const SizedBox(height: 16),
                                const Text('Detail HPP (Modal HOT)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...hppControllers.map((item) => Row(
                                  children: [
                                    Expanded(child: TextField(controller: item['desc'], decoration: const InputDecoration(hintText: 'Bahan/Biaya'))),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 70, child: TextField(
                                      controller: item['cost'], 
                                      keyboardType: TextInputType.number, 
                                      decoration: const InputDecoration(hintText: 'Harga'),
                                      onChanged: (_) => setDialogState(() {}),
                                    )),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                      onPressed: hppControllers.length > 1 ? () => setDialogState(() => hppControllers.remove(item)) : null,
                                    )
                                  ],
                                )),
                                TextButton.icon(
                                  onPressed: () => setDialogState(() => hppControllers.add({'desc': TextEditingController(), 'cost': TextEditingController()})),
                                  icon: const Icon(Icons.add_circle),
                                  label: const Text('Tambah Baris HPP'),
                                ),
                                Text('Total HPP: ${currencyFormat.format(totalHpp)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                            TextButton(onPressed: () async {
                              List<Map<String, dynamic>> hppData = hppControllers.map((e) => {
                                'desc': e['desc']!.text,
                                'cost': double.tryParse(e['cost']!.text) ?? 0
                              }).toList();

                              final product = Product(
                                id: p.id, 
                                name: p.name, 
                                price: double.parse(cPrice.text), 
                                hpp: totalHpp, 
                                priceBotol: double.tryParse(cPriceBotol.text),
                                hppBotol: double.tryParse(cHppBotol.text),
                                hppDetails: jsonEncode(hppData),
                                categoryId: p.categoryId, 
                                imagePath: selectedImagePath
                              );

                              bool success = false;
                              if (_isCloudSync) {
                                success = await _ssService.addProduct(product); // addProduct is used for update as well in simple GS
                              } else {
                                await _dbHelper.updateProduct(product);
                                success = true;
                              }
                              
                              if (success) {
                                _loadData();
                                _selectCategory(_selectedCategory!);
                                if (mounted) Navigator.pop(context);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan ke Cloud!')));
                                }
                              }
                            }, child: const Text('Simpan')),
                          ],
                        );
                      }
                    ));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(color: Colors.brown[50], shape: BoxShape.circle),
                                child: ClipOval(
                                  child: p.imagePath != null
                                      ? (p.imagePath!.startsWith('http')
                                          ? Image.network(p.imagePath!, fit: BoxFit.cover, width: 40, height: 40)
                                          : (kIsWeb 
                                              ? Image.network(p.imagePath!, fit: BoxFit.cover, width: 40, height: 40)
                                              : Image.file(File(p.imagePath!), fit: BoxFit.cover, width: 40, height: 40)))
                                      : Icon(
                                          _selectedCategory?.name == 'OTHERS' ? Icons.cookie : Icons.coffee,
                                          size: 40,
                                          color: Colors.brown,
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.add_a_photo, size: 20, color: Colors.brown),
                                onPressed: () async {
                                  final x = await _picker.pickImage(source: ImageSource.gallery);
                                  if (x != null) {
                                    await _dbHelper.updateProduct(Product(
                                      id: p.id, 
                                      name: p.name, 
                                      price: p.price, 
                                      hpp: p.hpp, 
                                      priceBotol: p.priceBotol,
                                      hppBotol: p.hppBotol,
                                      hppDetails: p.hppDetails,
                                      categoryId: p.categoryId, 
                                      imagePath: x.path
                                    ));
                                    _loadData();
                                    _selectCategory(_selectedCategory!);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.name, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), 
                                textAlign: TextAlign.center, 
                                maxLines: 2, 
                                overflow: TextOverflow.ellipsis
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(p.price), 
                                style: TextStyle(color: Colors.brown[700], fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100], 
                                  borderRadius: BorderRadius.circular(4), 
                                  border: Border.all(color: Colors.blue[300]!)
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, size: 10, color: Colors.black),
                                    SizedBox(width: 4),
                                    Text('Edit', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              final cDesc = TextEditingController();
              final cAmount = TextEditingController();
              showDialog(context: context, builder: (context) => AlertDialog(
                title: const Text('Tambah Pengeluaran'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: cDesc, decoration: const InputDecoration(labelText: 'Keterangan (Contoh: Beli Susu)')),
                    TextField(controller: cAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal')),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                  TextButton(onPressed: () async {
                    await _dbHelper.insertExpense(Expense(
                      description: cDesc.text,
                      amount: double.parse(cAmount.text),
                      dateTime: DateTime.now(),
                    ));
                    _loadExpenses();
                    if (mounted) Navigator.pop(context);
                  }, child: const Text('Tambah')),
                ],
              ));
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Pengeluaran Baru'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _expenses.length,
            itemBuilder: (context, i) {
              final e = _expenses[i];
              return ListTile(
                title: Text(e.description),
                subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(e.dateTime)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currencyFormat.format(e.amount), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () async {
                      await _dbHelper.deleteExpense(e.id!);
                      _loadExpenses();
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportTab() {
    double totalSales = _reports.fold(0, (sum, r) => sum + r.totalAmount);
    double totalDiscount = _reports.fold(0, (sum, r) => sum + r.discount);
    double totalExpenses = _expenses.fold(0, (sum, e) => sum + e.amount);
    double grossProfit = totalSales - _totalHpp;
    double netProfit = grossProfit - totalExpenses;

    return Column(
      children: [
        // Date Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.brown[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rentang Laporan:', style: TextStyle(fontSize: 12, color: Colors.brown)),
                  Text(
                    '${DateFormat('dd/MM/yy').format(_dateRange.start)} - ${DateFormat('dd/MM/yy').format(_dateRange.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Filter'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.file_download, color: Colors.green),
                    tooltip: 'Ekspor Excel',
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Transaction List
        Expanded(
          child: _reports.isEmpty
              ? const Center(child: Text('Tidak ada transaksi', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: _reports.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = _reports[i];
                    return ListTile(
                      dense: true,
                      title: Text('${r.paymentMethod} - ${currencyFormat.format(r.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(r.dateTime)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Transaksi'),
                              content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                TextButton(
                                  onPressed: () async {
                                    await _dbHelper.deleteTransaction(r.id!);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                    _loadReports();
                                  },
                                  child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () async {
                        final details = await _dbHelper.getTransactionDetails(r.id!);
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Detail Transaksi'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: details.map((d) => ListTile(
                                  dense: true,
                                  title: Text('${d['productName']} (${d['variant'] ?? "Cup"})'),
                                  trailing: Text('x${d['quantity']} @${currencyFormat.format(d['price'])}'),
                                )).toList(),
                              ),
                              actions: [
                                TextButton.icon(
                                  onPressed: () async {
                                    if (_selectedDevice != null) {
                                      List<CartItem> items = details.map((d) {
                                        return CartItem(
                                          product: Product(
                                            name: d['productName'],
                                            price: d['price'],
                                            hpp: d['hpp'] ?? 0,
                                            categoryId: 0,
                                          ),
                                          quantity: d['quantity'],
                                          variant: d['variant'] ?? "Cup",
                                        );
                                      }).toList();
                                      
                                      await PrinterService().printReceipt(
                                        device: _selectedDevice!,
                                        items: items,
                                        total: r.totalAmount,
                                        discount: r.discount,
                                        cash: r.paymentMethod == 'Tunai' ? r.totalAmount + r.discount : r.totalAmount, // Rough estimation as cash/change isn't stored separately for old transactions
                                        change: 0,
                                        paymentMethod: r.paymentMethod,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer belum diset!')));
                                    }
                                  },
                                  icon: const Icon(Icons.print),
                                  label: const Text('Cetak Struk'),
                                ),
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))
                              ],
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
        // Summary Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: Column(
            children: [
              _reportRow('Total Penjualan (Net)', totalSales, Colors.black),
              _reportRow('Total Diskon Diberikan', totalDiscount, Colors.blueGrey),
              _reportRow('Total HPP Produk', _totalHpp, Colors.orange[800]!),
              _reportRow('Laba Kotor', grossProfit, Colors.blue),
              const Divider(),
              _reportRow('Total Biaya Operasional', totalExpenses, Colors.red),
              const Divider(),
              _reportRow('Laba/Rugi Bersih', netProfit, netProfit >= 0 ? Colors.green : Colors.red, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              final cNum = TextEditingController();
              final cLoc = TextEditingController();
              showDialog(context: context, builder: (context) => AlertDialog(
                title: const Text('Tambah Meja Baru'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: cNum, decoration: const InputDecoration(labelText: 'Nomor Meja')),
                    TextField(controller: cLoc, decoration: const InputDecoration(labelText: 'Lokasi (Contoh: Lantai 2)')),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                  TextButton(onPressed: () async {
                    await _dbHelper.insertTable(CafeTable(
                      number: cNum.text,
                      location: cLoc.text,
                    ));
                    _loadTables();
                    if (mounted) Navigator.pop(context);
                  }, child: const Text('Tambah')),
                ],
              ));
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Meja'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _tables.length,
            itemBuilder: (context, i) {
              final t = _tables[i];
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.brown, child: Text(t.number, style: const TextStyle(color: Colors.white))),
                title: Text('Meja ${t.number}'),
                subtitle: Text(t.location),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {
                      final cNum = TextEditingController(text: t.number);
                      final cLoc = TextEditingController(text: t.location);
                      showDialog(context: context, builder: (context) => AlertDialog(
                        title: const Text('Edit Meja'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: cNum, decoration: const InputDecoration(labelText: 'Nomor Meja')),
                            TextField(controller: cLoc, decoration: const InputDecoration(labelText: 'Lokasi')),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                          TextButton(onPressed: () async {
                            await _dbHelper.updateTable(CafeTable(
                              id: t.id,
                              number: cNum.text,
                              location: cLoc.text,
                              isOccupied: t.isOccupied,
                            ));
                            _loadTables();
                            if (mounted) Navigator.pop(context);
                          }, child: const Text('Simpan')),
                        ],
                      ));
                    }),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      await _dbHelper.deleteTable(t.id!);
                      _loadTables();
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddProductDialog() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu!')));
      return;
    }

    final cName = TextEditingController();
    final cPrice = TextEditingController();
    final cPriceBotol = TextEditingController();
    final cHppBotol = TextEditingController();
    List<Map<String, TextEditingController>> hppControllers = [
      {'desc': TextEditingController(), 'cost': TextEditingController()}
    ];
    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double totalHpp = hppControllers.fold(0, (sum, item) {
            double val = double.tryParse(item['cost']!.text) ?? 0;
            return sum + val;
          });

          return AlertDialog(
            title: Text('Tambah Menu ${_selectedCategory!.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final x = await _picker.pickImage(source: ImageSource.gallery);
                          if (x != null) {
                            setDialogState(() => selectedImagePath = x.path);
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.brown[200]!),
                          ),
                          child: selectedImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? Image.network(selectedImagePath!, fit: BoxFit.cover)
                                      : Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.brown),
                                    Text('Foto', style: TextStyle(fontSize: 10, color: Colors.brown)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: cName, decoration: const InputDecoration(labelText: 'Nama Produk'))),
                    ],
                  ),
                  TextField(controller: cPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual (HOT)')),
                  TextField(controller: cPriceBotol, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual (ICE) - Opsional')),
                  TextField(controller: cHppBotol, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'HPP (ICE) - Opsional')),
                  const SizedBox(height: 16),
                  const Text('Detail HPP (Modal HOT)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...hppControllers.map((item) => Row(
                    children: [
                      Expanded(child: TextField(controller: item['desc'], decoration: const InputDecoration(hintText: 'Bahan/Biaya'))),
                      const SizedBox(width: 8),
                      SizedBox(width: 80, child: TextField(
                        controller: item['cost'], 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(hintText: 'Harga'),
                        onChanged: (_) => setDialogState(() {}),
                      )),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: hppControllers.length > 1 ? () => setDialogState(() => hppControllers.remove(item)) : null,
                      )
                    ],
                  )),
                  TextButton.icon(
                    onPressed: () => setDialogState(() => hppControllers.add({'desc': TextEditingController(), 'cost': TextEditingController()})),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Tambah Baris HPP'),
                  ),
                  Text('Total HPP HOT: ${currencyFormat.format(totalHpp)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              TextButton(
                onPressed: () async {
                  if (cName.text.isNotEmpty && cPrice.text.isNotEmpty) {
                    List<Map<String, dynamic>> hppData = hppControllers.map((e) => {
                      'desc': e['desc']!.text,
                      'cost': double.tryParse(e['cost']!.text) ?? 0
                    }).toList();
                    
                    final product = Product(
                      name: cName.text,
                      price: double.parse(cPrice.text),
                      hpp: totalHpp,
                      priceBotol: double.tryParse(cPriceBotol.text),
                      hppBotol: double.tryParse(cHppBotol.text),
                      hppDetails: jsonEncode(hppData),
                      categoryId: _selectedCategory!.id!,
                      imagePath: selectedImagePath,
                    );

                    bool success = false;
                    if (_isCloudSync) {
                      success = await _ssService.addProduct(product);
                    } else {
                      await _dbHelper.insertProduct(product);
                      success = true;
                    }

                    if (success) {
                      _loadData();
                      _selectCategory(_selectedCategory!);
                      if (mounted) Navigator.pop(context);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan ke Cloud!')));
                      }
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reportRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(currencyFormat.format(value), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }
}
