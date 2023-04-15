import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
   const ErrorScreen(this.errorMessage, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar( 
        title: const Text('Internal Error'),
      ),
      body: Text(
        'Internal Error.\n Restart the app!\n$errorMessage',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 28.0,
        )
      ),
    );
  }
}