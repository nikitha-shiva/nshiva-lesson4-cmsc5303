import 'package:flutter/material.dart';

void showSnackBar({
  required BuildContext context,
  required String message,
  int? seconds,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: seconds ?? 3), // 3 sec default
    action: SnackBarAction(
      label: 'OK',
      onPressed: () {},
    ), // SnackBarAction
  ); // SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void showAlertDialog({
  required BuildContext context,
  required String title,
  required Widget widget,
}) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.lime[200],
          title: Text(title),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
          content: widget,
        );
      });
}