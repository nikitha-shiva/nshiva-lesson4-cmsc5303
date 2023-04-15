import 'package:firebase_auth/firebase_auth.dart';
import 'package:lesson4/model/photomemo.dart';

class SharedWithScreenModel {
  List<PhotoMemo>? sharedWithList;
  final User user;
  String? loadingErrorMessage;

  SharedWithScreenModel({required this.user});
}