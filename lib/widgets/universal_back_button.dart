import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UniversalBackButton extends StatelessWidget {
  const UniversalBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back),
          SizedBox(width: 4),
          Text('Back'),
        ],
      ),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
    );
  }
}
