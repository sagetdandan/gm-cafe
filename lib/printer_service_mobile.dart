import 'dart:io';
import 'package:flutter/services.dart' hide Category;
// import 'package:blue_thermal_printer/blue_thermal_printer.dart' as blue;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'printer_service.dart';

PrinterServiceProvider getPrinterProvider() => MobilePrinterProvider();

class MobilePrinterProvider implements PrinterServiceProvider {
  // blue.BlueThermalPrinter bluetooth = blue.BlueThermalPrinter.instance;

  @override
  Future<List<AppBluetoothDevice>> getDevices() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // List<blue.BluetoothDevice> devices = await bluetooth.getBondedDevices();
      // return devices.map((d) => AppBluetoothDevice(d.name, d.address)).toList();
    }
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
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final prefs = await SharedPreferences.getInstance();
    final String address = prefs.getString('shop_address') ?? "Jl. Contoh No. 123";
    final String footer = prefs.getString('shop_footer') ?? "Terima Kasih Atas Kunjungan Anda";
    final String paperSize = prefs.getString('paper_size') ?? '58mm';
    
    // blue.BluetoothDevice targetDevice = blue.BluetoothDevice(device.name, device.address);

    /*
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      try {
        await bluetooth.connect(targetDevice);
      } catch (e) {
        return;
      }
    }
    */

    final df = DateFormat('dd-MM-yyyy HH:mm');
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    /*
    try {
      final String? logoPath = prefs.getString('shop_logo_path');
      if (logoPath != null && File(logoPath).existsSync()) {
        await bluetooth.printImage(logoPath);
      } else {
        ByteData bytes = await rootBundle.load('assets/logo_gm_cafe.png');
        String tempPath = (await getTemporaryDirectory()).path;
        File file = File('$tempPath/logo_struk.png');
        await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        await bluetooth.printImage(file.path);
      }
    } catch (e) {
      // bluetooth.printCustom("Gadungmelati Cafe", 3, 1);
    }
    */

    /*
    bluetooth.printCustom(address, 1, 1);
    
    final String line = paperSize == '80mm' ? "------------------------------------------------" : "--------------------------------";
    
    bluetooth.printCustom(line, 1, 1);
    bluetooth.printCustom("Tgl: ${df.format(DateTime.now())}", 1, 0);
    bluetooth.printCustom("Metode: $paymentMethod", 1, 0);
    bluetooth.printCustom(line, 1, 1);

    for (var item in items) {
      String name = item.product.name;
      if (item.variant != "Cup") {
        name += " (${item.variant})";
      }
      bluetooth.printLeftRight("$name x${item.quantity}", currency.format(item.totalPrice), 1);
    }

    bluetooth.printCustom(line, 1, 1);
    if (discount > 0) {
      bluetooth.printLeftRight("SUBTOTAL", currency.format(total + discount), 1);
      bluetooth.printLeftRight("DISKON", "-${currency.format(discount)}", 1);
    }
    bluetooth.printLeftRight("TOTAL", currency.format(total), 2);
    bluetooth.printLeftRight("BAYAR", currency.format(cash), 1);
    bluetooth.printLeftRight("KEMBALI", currency.format(change), 1);
    bluetooth.printCustom(line, 1, 1);
    bluetooth.printCustom(footer, 1, 1);

    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.paperCut();
    */
  }
}

