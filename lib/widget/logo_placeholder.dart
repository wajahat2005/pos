import 'dart:io';
import 'package:flutter/material.dart';

class LogoPlaceholder extends StatelessWidget {
  final String? logoPath;
  final double size;

  const LogoPlaceholder({
    super.key,
    required this.logoPath,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (logoPath != null && logoPath!.isNotEmpty) {
      final file = File(logoPath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            height: size,
            width: size,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            color: Colors.grey[500],
            size: size * 0.4,
          ),
          const SizedBox(height: 4),
          Text(
            'Logo Here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: size * 0.12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
