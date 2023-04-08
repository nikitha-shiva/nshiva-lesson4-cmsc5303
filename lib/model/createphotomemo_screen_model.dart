import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lesson4/model/photomemo.dart';

class CreatePhotoMemoScreenModel {
  User user;
  dynamic photo; // mobile (File) web (Uint8List)
  String? photoMimeType;
  late PhotoMemo tempMemo;
  String? progressMessage;

  CreatePhotoMemoScreenModel({required this.user}) {
       tempMemo = PhotoMemo(
        createdBy: user.email!,
        memo: '',
        photoFilename: '',
        photoURL: '',
        title: '',
     );
  }

  void saveTitle(String? value) {
    if (value != null) {
      tempMemo.title = value;
    }
  }

  void saveMemo(String? value) {
    if (value != null) {
      tempMemo.memo = value;
    }
  }

  void saveSharedWith(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      List<String> emailList = 
 value.trim().split(RegExp('(,|;| )+')).map((e)=>e.trim()).toList();
   tempMemo.sharedWith = emailList;
    }
  }
  }