import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lesson4/controller/auth_controller.dart';
import 'package:lesson4/controller/firestore_controller.dart';
import 'package:lesson4/controller/storage_controller.dart';
import 'package:lesson4/model/constants.dart';
import 'package:lesson4/model/createphotomemo_screen_model.dart';
import 'package:lesson4/model/photomemo.dart';
import 'package:lesson4/viewscreen/view/view_util.dart';

class CreatePhotoMemoScreen extends StatefulWidget {
  static const routeName = '/createPhotoMemoScreen';

  const CreatePhotoMemoScreen({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _CreatePhotoMemoState();
  }
}

class _CreatePhotoMemoState extends State<CreatePhotoMemoScreen> {
  late _Controller con;
  late CreatePhotoMemoScreenModel screenModel;
  var formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    screenModel = CreatePhotoMemoScreenModel(user: Auth.user!);
  }

  void render(fn) => setState(fn);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${screenModel.user.email}: Create New'),
        actions: [
          IconButton(
            onPressed: screenModel.progressMessage == null ? con.save : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              photoPreview(),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Title'),
                autocorrect: true,
                validator: PhotoMemo.validateTitle,
                onSaved: screenModel.saveTitle,
              ),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Memo'),
                autocorrect: true,
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                validator: PhotoMemo.validateTitle,
                onSaved: screenModel.saveMemo,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Shared With (email list separated by space , ;',
                ),
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                maxLines: 2,
                validator: PhotoMemo.validateSharedWith,
                onSaved: screenModel.saveSharedWith,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget photoPreview() {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: screenModel.photo == null
              ? const FittedBox(child: Icon(Icons.photo_library))
              : (kIsWeb
                  ? Image.memory(screenModel.photo)
                  : Image.file(screenModel.photo!)),
        ),
        Positioned(
          right: 0.0,
          bottom: 0.0,
          child: Container(
            color: Colors.blue[200],
            child: PopupMenuButton(
              onSelected: con.getPhoto,
              itemBuilder: (context) {
                if (kIsWeb) {
                  return [
                    PopupMenuItem(
                      value: PhotoSource.gallery,
                      child: Text(PhotoSource.gallery.name.toUpperCase()),
                    ),
                  ];
                } else {
                  return [
                    for (var source in PhotoSource.values)
                      PopupMenuItem(
                        value: source,
                        child: Text(source.name.toUpperCase()),
                      ),
                  ];
                }
              },
            ),
          ),
        ),
        if (screenModel.progressMessage != null)
          Positioned(
            bottom: 0.0,
            left: 0.0,
            child: Container(
              color: Colors.blue[200],
              child: Text(
                screenModel.progressMessage!,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _Controller {
  _CreatePhotoMemoState state;
  _Controller(this.state);

  Future<void> save() async {
    FormState? currentState = state.formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }
    if (state.screenModel.photo == null) {
      showSnackBar(context: state.context, message: 'Photo not selected');
      return;
    }
    currentState.save();

    try {
      Map<ArgKey, String> result = await StorageController.uploadPhotoFile(
          photo: state.screenModel.photo!,
          photoMimeType: state.screenModel.photoMimeType!,
          uid: state.screenModel.user.uid,
          listener: (int progress) {
            state.render(() {
              if (progress == 100) {
                state.screenModel.progressMessage = null;
              } else {
                state.screenModel.progressMessage = 'Uploading: $progress %';
              }
            });
          });
          state.render(
            () => state.screenModel.progressMessage = 'Saving photomemo ...');
          state.screenModel.tempMemo.photoFilename = result[ArgKey.filename]!;
          state.screenModel.tempMemo.photoURL = result[ArgKey.downloadURL]!;
          state.screenModel.tempMemo.createdBy = state.screenModel.user.email!;
          state.screenModel.tempMemo.timestamp = DateTime.now(); // millisec from 1970/1/1

          String docId = await FirestoreController.addPhotoMemo(
            photoMemo: state.screenModel.tempMemo);
            state.screenModel.tempMemo.docId = docId;
            state.screenModel.progressMessage = null;
            // When a BuildContext is used from a StatefulWidget
            // the mount property must be checked after an async gap
             if (!state.mounted) return;

             Navigator.of(state.context).pop(state.screenModel.tempMemo);
    } catch (e) {
       state.render(
            () => state.screenModel.progressMessage = null);
      if (Constant.devMode) print('********* upload photo/doc error: $e');
      showSnackBar(
          context: state.context, message: 'Upload Photo/doc error: $e');
    }
  }

  Future<void> getPhoto(PhotoSource source) async {
    try {
      var imageSource = source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      XFile? image = await ImagePicker().pickImage(source: imageSource);
      if (image == null) return; // cancelled at camera or gallery
      state.screenModel.photoMimeType = image.mimeType;
      if (kIsWeb) {
        state.screenModel.photo = await image.readAsBytes();
      } else {
        state.screenModel.photo = File(image.path);
      }
      state.render(() {});
    } catch (e) {
      if (Constant.devMode) print('===== failed to get pic: $e');
      showSnackBar(context: state.context, message: 'Failed to get a pic: $e');
    }
  }
}
