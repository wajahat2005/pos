import 'dart:io';
import 'package:due_kasir/model/penjualan_model.dart';
import 'package:due_kasir/model/store_model.dart';
import 'package:due_kasir/model/audit_model.dart';
import 'package:due_kasir/service/database.dart';
import 'package:due_kasir/utils/constant.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart' as usb_esc_printer_windows;

class PrintService {
  static Future<void> letsPrint({
    required StoreModel store,
    required PenjualanModel model,
    required String kasir,
    String? customerName,
    String? printName,
  }) async {
    final profile = await CapabilityProfile.load();
    late CapabilityProfile winProfile;
    if (Platform.isWindows) {
      winProfile = await CapabilityProfile.load();
    }
    
    // Check Paper Size from store settings
    final is58mm = store.paperSize == '58 mm';
    final generator = Generator(is58mm ? PaperSize.mm58 : PaperSize.mm80, Platform.isWindows ? winProfile : profile);
    
    List<int> bytes = [];

    // Print Logo
    if (store.logoPath != null && store.logoPath!.isNotEmpty) {
      try {
        final logoFile = File(store.logoPath!);
        if (await logoFile.exists()) {
          final logoBytes = await logoFile.readAsBytes();
          final image = img.decodeImage(logoBytes);
          if (image != null) {
            final maxWidth = is58mm ? 384 : 576;
            img.Image resized = image;
            if (image.width > maxWidth) {
              resized = img.copyResize(image, width: maxWidth);
            }
            bytes += generator.image(resized);
          }
        }
      } catch (e) {
        final db = await Database().db;
        await db.writeTxn(() async {
          await db.auditModels.put(AuditModel(action: 'PRINT_FAILED', details: 'Logo print failed: $e'));
        });
      }
    }

    // Store Info
    bytes += generator.text(store.title, styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
    bytes += generator.feed(1);
    bytes += generator.text(store.description, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(store.phone, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.hr();
    
    // Receipt Details
    bytes += generator.text('Bill No   : ${model.billNumber ?? model.id}');
    bytes += generator.text('Date      : ${DateFormat('yyyy-MM-dd HH:mm').format(model.createdAt)}');
    bytes += generator.text('Cashier   : $kasir');
    if (customerName != null && customerName.isNotEmpty) {
      bytes += generator.text('Customer  : $customerName');
    }
    bytes += generator.feed(1);
    bytes += generator.hr();

    // Items
    for (var i in model.items) {
      bytes += generator.text(i.nama ?? '');
      bytes += generator.row([
        PosColumn(
          text: '${i.quantity} x ${currency.format(i.hargaJual)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: currency.format(i.quantity! * i.hargaJual!),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += [27, 97, 2];
    bytes += generator.text(
      'Total ${store.currencySymbol ?? "Rs"} ${currency.format(model.totalHarga).replaceAll(RegExp(r'^Rs\s*'), '')}',
      styles: const PosStyles(height: PosTextSize.size2, bold: true),
    );
    bytes += [27, 97, 1];
    
    // Footer
    bytes += generator.feed(2);
    if (store.footer != null && store.footer!.isNotEmpty) {
      bytes += generator.text(store.footer!, styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(1);
    bytes += generator.text('Thank You For Visiting', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(1);
    bytes += generator.text('Designed & Developed by Mazhar Abbas', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.drawer();

    if (Platform.isWindows) {
      final res = await usb_esc_printer_windows.sendPrintRequest(bytes, printName ?? 'Xprinter XP-T371U');
      if (res != 'success') {
        throw Exception(res);
      }
    } else {
      final success = await PrintBluetoothThermal.writeBytes(bytes);
      if (!success) {
        throw Exception('Bluetooth printing failed');
      }
    }
  }
}
