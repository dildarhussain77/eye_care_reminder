import 'package:flutter/material.dart';

class AppSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 6,
      ),
    );
  }
}