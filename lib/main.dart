import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lesson4/viewscreen/createphotomemo_screen.dart';
import 'package:lesson4/viewscreen/startdispatcher.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const PhotoMemoApp());
}

class PhotoMemoApp extends StatelessWidget {
  const PhotoMemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: StartDispatcher.routeName,
      routes: {
         StartDispatcher.routeName: (context) => const StartDispatcher(),
         CreatePhotoMemoScreen.routeName: (context) => const CreatePhotoMemoScreen(),
      },
    );
  }

}
