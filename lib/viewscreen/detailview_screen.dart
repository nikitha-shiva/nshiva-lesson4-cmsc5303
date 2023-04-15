import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lesson4/controller/firestore_controller.dart';
import 'package:lesson4/controller/storage_controller.dart';
import 'package:lesson4/model/detailview_screen_model.dart';
import 'package:lesson4/viewscreen/view/view_util.dart';
import 'package:lesson4/viewscreen/view/webimage.dart';

import '../controller/auth_controller.dart';
import '../model/constants.dart';
import '../model/photomemo.dart';

class DetailViewScreen extends StatefulWidget {
  static const routeName = '/detailViewScreen';
  final PhotoMemo photoMemo;

  const DetailViewScreen({required this.photoMemo, Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _DetailViewState();
  }
}

class _DetailViewState extends State<DetailViewScreen> {
  late _Controller con;
  late DetailViewScreenModel screenModel;
  var formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    screenModel = DetailViewScreenModel(
      user: Auth.user!,
      photoMemo: widget.photoMemo,
    );
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${screenModel.user.email}: Detail view'),
        actions: [
          screenModel.editMode
              ? IconButton(onPressed: screenModel.progressMessage !=null ? null: con.update, icon: const Icon(Icons.check))
              : IconButton(onPressed: con.edit, icon: const Icon(Icons.edit)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                photoEditView(),
                TextFormField(
                  enabled: screenModel.editMode,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    hintText: 'Enter Title',
                  ),
                  initialValue: screenModel.tempMemo.title,
                  validator: PhotoMemo.validateTitle,
                  onSaved: screenModel.saveTitle,
                ),
                TextFormField(
                  enabled: screenModel.editMode,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    hintText: 'Enter memo',
                  ),
                  initialValue: screenModel.tempMemo.memo,
                  keyboardType: TextInputType.multiline,
                  maxLines: 6,
                  validator: PhotoMemo.validateMemo,
                  onSaved: screenModel.saveMemo,
                ),
                TextFormField(
                  enabled: screenModel.editMode,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    hintText: 'Enter shared with email List',
                  ),
                  initialValue: screenModel.tempMemo.sharedWith.join(' '),
                  keyboardType: TextInputType.emailAddress,
                  maxLines: 2,
                  validator: PhotoMemo.validateSharedWith,
                  onSaved: screenModel.saveSharedWith,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget photoEditView() {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: screenModel.photo == null
              ? WebImage(
                  url: screenModel.tempMemo.photoURL,
                  context: context,
                )
              : (kIsWeb
                  ? Image.memory(screenModel.photo)
                  : Image.file(screenModel.photo!)),
        ),
        if (screenModel.editMode)
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
          if(screenModel.progressMessage != null)
            Positioned(
              left:0,
              bottom: 0,
              child: Container(
                color: Colors.blue[200],
                child: Text(
                  screenModel.progressMessage!,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            )
            
      ],
    );
  }
}

class _Controller {
  _DetailViewState state;
  _Controller(this.state);

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

  Future<void> uploadNewImageFile(Map<String, dynamic> fieldsToUpdate) async {
    Map result = await StorageController.uploadPhotoFile(
      photo: state.screenModel.photo!,
      photoMimeType: state.screenModel.photoMimeType!,
      uid: state.screenModel.user.uid,
      listener: (int progress) {
        state.render(() {
          state.screenModel.progressMessage =
              progress == 100 ? null : 'Uploading: $progress %';
        
        });
      },
    );
    state.screenModel.tempMemo.photoFilename = result[ArgKey.filename];
    state.screenModel.tempMemo.photoURL = result[ArgKey.downloadURL];
    fieldsToUpdate[DocKeyPhotoMemo.photoFilename.name] =
        result[ArgKey.filename];
    fieldsToUpdate[DocKeyPhotoMemo.photoURL.name] = result[ArgKey.downloadURL];
  }

  void setUpdateFields(Map<String, dynamic> fieldsToUpdate){
    if(state.screenModel.tempMemo.title != state.screenModel.photoMemo.title){
      fieldsToUpdate[DocKeyPhotoMemo.title.name] = 
        state.screenModel.tempMemo.title;
    }
    if(state.screenModel.tempMemo.memo != state.screenModel.photoMemo.memo){
      fieldsToUpdate[DocKeyPhotoMemo.memo.name] = 
        state.screenModel.tempMemo.memo;
    }
    if(!listEquals(state.screenModel.tempMemo.sharedWith, state.screenModel.tempMemo.sharedWith)){
      fieldsToUpdate[DocKeyPhotoMemo.sharedWith.name] = 
        state.screenModel.tempMemo.sharedWith;
    }

  }

  void update() async {
    FormState? currentState = state.formKey.currentState;
    if (currentState == null) return;
    if (!currentState.validate()) return;
    currentState.save();

    Map<String, dynamic> fieldsToUpdate = {};
    try {
      if (state.screenModel.photo != null) {
        await uploadNewImageFile(fieldsToUpdate);
      }
    

    setUpdateFields(fieldsToUpdate);

    if(fieldsToUpdate.isEmpty) 
    {
      state.render(() {
        state.screenModel.progressMessage = null;
        state.screenModel.editMode = false;
      });
      if(state.mounted){
      showSnackBar(context: state.context, message: 'No changes are made',);
      }
    } else {
      state.screenModel.tempMemo.timestamp = DateTime.now();
      fieldsToUpdate[DocKeyPhotoMemo.timestamp.name] =  state.screenModel.tempMemo.timestamp;
      state.render((){
        state.screenModel.progressMessage = 'Updating photomemo doc';
      });
      await FirestoreController.updatePhotoMemo(docId: state.screenModel.tempMemo.docId!,
       update: fieldsToUpdate,
      );

      if (state.screenModel.photo != null){
        await StorageController.deleteFile(filename: state.screenModel.photoMemo.photoFilename,
        );
      }

      state.screenModel.photoMemo.copy(state.screenModel.tempMemo);
      state.screenModel.editMode = false;
      state.screenModel.progressMessage = null;
      if(state.mounted){
      Navigator.of(state.context).pop(true);
      }
    }
    } catch (e) {
      state.render((){
        state.screenModel.progressMessage = null;
      });
      if(fieldsToUpdate[DocKeyPhotoMemo.photoFilename] != null){
        await StorageController.deleteFile(filename: state.screenModel.tempMemo.photoFilename,
        );
      }
      if (Constant.devMode) print('============== $e');
      if(state.mounted){
      showSnackBar(context: state.context, message: 'failed to update: $e');
      }
    }
    state.render(() {
      state.screenModel.editMode = false;
    });
  }

  void edit() {
    state.render(() {
      state.screenModel.editMode = true;
    });
  }
}
