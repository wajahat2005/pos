import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

void main() async {
  print('Starting packaging of Wajahat POS...');

  // 1. Run User Guide generator
  print('Generating User Guide PDF...');
  final userGuideResult = await Process.run('dart', ['run', 'scripts/generate_user_guide.dart']);
  if (userGuideResult.exitCode != 0) {
    print('Failed to generate user guide: ${userGuideResult.stderr}');
    return;
  }
  print('User Guide generated successfully.');

  final releaseDir = Directory('Wajahat_v1');
  if (await releaseDir.exists()) {
    print('Cleaning old Wajahat_v1 directory...');
    await releaseDir.delete(recursive: true);
  }
  await releaseDir.create(recursive: true);

  // Create subfolders
  await Directory('Wajahat_v1/Backups').create(recursive: true);
  await Directory('Wajahat_v1/Exports').create(recursive: true);
  await Directory('Wajahat_v1/Logos').create(recursive: true);
  await Directory('Wajahat_v1/Sample_Data').create(recursive: true);

  // 2. Copy build files
  final buildReleasePath = 'build/windows/x64/runner/Release';
  final buildDir = Directory(buildReleasePath);
  if (!await buildDir.exists()) {
    print('Error: Release build directory not found at $buildReleasePath');
    return;
  }

  print('Copying runtime files...');
  await for (final entity in buildDir.list(recursive: true)) {
    final relativePath = p.relative(entity.path, from: buildReleasePath);
    final targetPath = p.join('Wajahat_v1', relativePath);

    if (entity is Directory) {
      await Directory(targetPath).create(recursive: true);
    } else if (entity is File) {
      final parentDir = Directory(p.dirname(targetPath));
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      
      // Rename binary
      if (p.basename(entity.path) == 'due_kasir.exe') {
        final renamedPath = p.join(p.dirname(targetPath), 'wajahat.exe');
        await entity.copy(renamedPath);
      } else {
        await entity.copy(targetPath);
      }
    }
  }

  // 3. Move User Guide PDF to Wajahat_v1
  final generatedPdf = File('Wajahat_v1/User_Guide.pdf');
  if (!await generatedPdf.exists()) {
    // If it was generated in the project root, copy it over
    final rootPdf = File('User_Guide.pdf');
    if (await rootPdf.exists()) {
      await rootPdf.rename('Wajahat_v1/User_Guide.pdf');
    }
  }

  // 4. Create README.txt and CHANGELOG.md if not existing in Wajahat_v1
  final readmeFile = File('Wajahat_v1/README.txt');
  await readmeFile.writeAsString('''Wajahat POS - Portable Release v1.0.0
===================================================

Developed by Wajahat
Offline POS & Inventory Management System

To run the application:
1. Extract all files from this ZIP archive to a folder of your choice.
2. Double-click "wajahat.exe" to launch the system.

No installation, VS Code, or Flutter SDK required.
All data is stored safely in your Documents/Wajahat/ folder.
''');

  final changelogFile = File('Wajahat_v1/CHANGELOG.md');
  await changelogFile.writeAsString('''# Changelog - Wajahat POS

## [1.0.0] - 2026-07-16
- Initial Portable Release package.
- Added product images support with JPEG quality compression.
- Custom title bar and brand naming.
- Advanced secure storage integration for admin passwords, store settings, and printer configurations.
- Dynamic reset confirmation mechanism.
''');

  // 5. Generate ZIP archive using package:archive
  print('Compressing Wajahat_v1 into Wajahat_v1.zip...');
  final encoder = ZipFileEncoder();
  encoder.create('Wajahat_v1.zip');
  await encoder.addDirectory(Directory('Wajahat_v1'));
  encoder.close();

  final zipFile = File('Wajahat_v1.zip');
  if (await zipFile.exists()) {
    final sizeInMb = (await zipFile.length()) / (1024 * 1024);
    print('Packaging complete!');
    print('Final ZIP Location: Wajahat_v1.zip');
    print('Final ZIP Size: ${sizeInMb.toStringAsFixed(2)} MB');
  } else {
    print('Error: Failed to create Wajahat_v1.zip');
  }
}
