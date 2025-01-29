import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  final VoidCallback onResetPassword;

  const PasswordField({
    super.key,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onResetPassword,
          ),
        ],
      ),
    );
  }
}
