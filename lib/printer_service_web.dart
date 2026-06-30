import 'models.dart';
import 'printer_service.dart';

PrinterServiceProvider getPrinterProvider() => WebPrinterProvider();

class WebPrinterProvider implements PrinterServiceProvider {
  @override
  Future<List<AppBluetoothDevice>> getDevices() async {
    return [];
  }

  @override
  Future<void> printReceipt({
    required AppBluetoothDevice device,
    required List<CartItem> items,
    required double total,
    double discount = 0,
    required double cash,
    required double change,
    required String paymentMethod,
  }) async {
    print("Printing receipt is not supported on web.");
  }
}
