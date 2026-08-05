import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  static Future<String> getAdminPassword() async {
    final pass = await _storage.read(key: 'admin_password');
    return pass ?? '111111';
  }

  static Future<void> setAdminPassword(String password) async {
    await _storage.write(key: 'admin_password', value: password);
  }

  static Future<String> getSelectedPrinter() async {
    final pr = await _storage.read(key: 'selected_printer');
    return pr ?? 'Xprinter XP-T371U';
  }

  static Future<void> setSelectedPrinter(String printer) async {
    await _storage.write(key: 'selected_printer', value: printer);
  }

  // Store Settings
  static Future<void> saveStoreSettings({
    required String title,
    required String description,
    required String phone,
    String? footer,
    String? subFooter,
    String? logoPath,
    String? currencySymbol,
    String? paperSize,
    String? backupFolderPath,
  }) async {
    await _storage.write(key: 'store_title', value: title);
    await _storage.write(key: 'store_description', value: description);
    await _storage.write(key: 'store_phone', value: phone);
    await _storage.write(key: 'store_footer', value: footer ?? '');
    await _storage.write(key: 'store_sub_footer', value: subFooter ?? '');
    await _storage.write(key: 'store_logo_path', value: logoPath ?? '');
    await _storage.write(key: 'store_currency_symbol', value: currencySymbol ?? 'Rs');
    await _storage.write(key: 'store_paper_size', value: paperSize ?? '80 mm');
    await _storage.write(key: 'store_backup_folder_path', value: backupFolderPath ?? '');
  }

  static Future<Map<String, String>> getStoreSettings() async {
    return {
      'title': await _storage.read(key: 'store_title') ?? 'Wajahat POS',
      'description': await _storage.read(key: 'store_description') ?? 'Offline POS & Inventory Management System',
      'phone': await _storage.read(key: 'store_phone') ?? '',
      'footer': await _storage.read(key: 'store_footer') ?? '',
      'subFooter': await _storage.read(key: 'store_sub_footer') ?? '',
      'logoPath': await _storage.read(key: 'store_logo_path') ?? '',
      'currencySymbol': await _storage.read(key: 'store_currency_symbol') ?? 'Rs',
      'paperSize': await _storage.read(key: 'store_paper_size') ?? '80 mm',
      'backupFolderPath': await _storage.read(key: 'store_backup_folder_path') ?? '',
    };
  }
}
