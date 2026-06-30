import 'models.dart';

// Import bersyarat: default ke stub agar web compiler tidak error
import 'printer_service_stub.dart' 
  if (dart.library.io) 'printer_service_mobile.dart' 
  if (dart.library.html) 'printer_service_web.dart';

abstract class PrinterServiceProvider {
  Future<List<AppBluetoothDevice>> getDevices();
  Future<void> printReceipt({
    required AppBluetoothDevice device,
    required List<CartItem> items,
    required double total,
    double discount = 0,
    required double cash,
    required double change,
    required String paymentMethod,
  });
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final PrinterServiceProvider _provider = getPrinterProvider();

  Future<List<AppBluetoothDevice>> getDevices() => _provider.getDevices();

  Future<void> printReceipt({
    required AppBluetoothDevice device,
    required List<CartItem> items,
    required double total,
    double discount = 0,
    required double cash,
    required double change,
    required String paymentMethod,
  }) => _provider.printReceipt(
        device: device,
        items: items,
        total: total,
        discount: discount,
        cash: cash,
        change: change,
        paymentMethod: paymentMethod,
      );
}
