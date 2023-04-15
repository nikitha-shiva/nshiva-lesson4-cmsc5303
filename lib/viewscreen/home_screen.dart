import 'package:flutter/material.dart';
import 'package:lesson4/controller/auth_controller.dart';
import 'package:lesson4/controller/firestore_controller.dart';
import 'package:lesson4/controller/storage_controller.dart';
import 'package:lesson4/model/constants.dart';
import 'package:lesson4/model/home_screen_model.dart';
import 'package:lesson4/model/photomemo.dart';
import 'package:lesson4/viewscreen/createphotomemo_screen.dart';
import 'package:lesson4/viewscreen/detailview_screen.dart';
import 'package:lesson4/viewscreen/sharedwith_screen.dart';
import 'package:lesson4/viewscreen/view/view_util.dart';
import 'package:lesson4/viewscreen/view/webimage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
  return _HomeState();
  }
}

class _HomeState extends State<HomeScreen> {
  late _Controller con;
  late HomeScreenModel screenModel;
  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    screenModel = HomeScreenModel(user: Auth.user!);
    con.loadPhotoMemoList();
  }

void render(fn){
  setState(fn);
}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          title:  Text('Home: ${screenModel.user.email}'),
          actions: [  
            if(screenModel.deleteIndex != null)
            IconButton(  
              onPressed: con.delete,
              icon: const Icon(Icons.delete),
              color: Colors.redAccent[100],
            ),
          ],
        ),
      drawer: drawerView(),
       body: bodyView(),
       floatingActionButton: FloatingActionButton(
      onPressed: con.addButton,
      child: const Icon(Icons.add),
       ),
      ),
    );
  }

Widget bodyView(){
  if (screenModel.loadingErrorMessage != null) { 
    return Text( 
      'Internal Error while loading: ${screenModel.loadingErrorMessage}');
  } else if (screenModel.photoMemoList == null) { 
    return const Center(child: CircularProgressIndicator());
  } else { 
    return showPhotoMemoList();
  }
  }
    
    Widget showPhotoMemoList() {
     if (screenModel.photoMemoList!.isEmpty) { 
      return Text(
        'No PhotoMemo found!' ,
        style: Theme.of(context).textTheme.titleLarge,
      );
     } else { 
      return ListView.builder(
        itemCount: screenModel.photoMemoList!.length,
        itemBuilder: (context, index) { 
          PhotoMemo photoMemo = screenModel.photoMemoList![index];
          return ListTile( 
            selected: screenModel.deleteIndex == index,
            selectedTileColor: Colors.redAccent[100],
            leading: screenModel.deleteInProgress && screenModel.deleteIndex == index ?
              CircularProgressIndicator()
             : WebImage( 
              url: photoMemo.photoURL,
               context: context,
          ),
          trailing: const Icon(Icons.arrow_right),
          title: Text(photoMemo.title),
          subtitle: Column( 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ 
              Text(  
                photoMemo.memo.length >= 40
                ? '${photoMemo.memo.substring(0, 40)} ...'
                : photoMemo.memo,
              ),
              Text('Created By: ${photoMemo.createdBy}'),
              Text('SharedWith: ${photoMemo.sharedWith}'),
              Text('Timestamp: ${photoMemo.timestamp}'),
            ],
          ),
          onTap: () => con.onTap(index),
          onLongPress: () => con.onLongPress(index),
          );
        });
     }
    }
Widget drawerView() {
  return Drawer(
    child: ListView(
      children: [
        UserAccountsDrawerHeader(
          currentAccountPicture: const Icon(Icons.person, size: 70.0,),
          accountName: const Text('No profile'),
         accountEmail: Text(screenModel.user.email!),
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Shared with'),
          onTap: con.sharedWith,
        ),
        ListTile(
        leading: const Icon(Icons.logout), 
        title: const Text('Sign out'),
        onTap: con.signOut, 
        ),
      ],
    ),
  );
}
}

class _Controller {
  _HomeState state;
  _Controller(this.state);

  void onLongPress(int index){
    state.render((){
       if(state.screenModel.deleteIndex == null ||
    state.screenModel.deleteIndex != index){
      state.screenModel.deleteIndex = index;
    } else {
      state.screenModel.deleteIndex = null;
    }
    });
    
  }

Future<void> loadPhotoMemoList() async {
  try {
    state.screenModel.photoMemoList = 
    await FirestoreController.getPhotoMemoList(email: state.screenModel.user.email!);
    state.render(() {});
  } catch (e) {
     if (Constant.devMode) print('=== loading error: $e');
     state.render(() { 
     state.screenModel.loadingErrorMessage = '$e';
     });
  }
}
  void signOut() {
    Auth.signOut();
  }

  void addButton() async {
    final memo = await Navigator.pushNamed(  
      state.context, CreatePhotoMemoScreen.routeName);
      if (memo == null) { 
        // add screen cancel by back button
        return;
      }
      PhotoMemo newMemo = memo as PhotoMemo;
      state.render(() { 
        state.screenModel.photoMemoList!.insert(0,newMemo);
      });
    
  }
  void onTap(int index) async {
    if(state.screenModel.deleteIndex != null){
      state.render((){
        state.screenModel.deleteIndex = null;
      });
      return;
    }
    final updated = await 
    Navigator.pushNamed(
      state.context,
      DetailViewScreen.routeName,
      arguments: state.screenModel.photoMemoList![index],
    );
    if (updated == null) return ;

    state.render(() {
      state.screenModel.photoMemoList!.sort((a, b){
        if(a.timestamp!.isBefore(b.timestamp!)){
        return 1;
        }
        else if (a.timestamp!.isAfter(b.timestamp!)) {
           return -1;
        } else {
          return 0;
        }
      });
    });
  }

  void sharedWith(){
    Navigator.popAndPushNamed(state.context, SharedWithScreen.routeName);
  }

  Future<void> delete() async{
    state.render((){
      state.screenModel.deleteInProgress = true;
    });
    PhotoMemo p = 
    state.screenModel.photoMemoList![state.screenModel.deleteIndex!];
    try{
      await FirestoreController.deleteDoc(docId: p.docId!);
      await StorageController.deleteFile(filename: p.photoFilename);
      state.render(() {
        
        state.screenModel.photoMemoList!.removeAt(state.screenModel.deleteIndex!);
        state.screenModel.deleteIndex = null;
        state.screenModel.deleteInProgress = false;
      });
    }catch (e){
      state.render(() { 
        state.screenModel.deleteIndex = null;
        state.screenModel.deleteInProgress = false;
    });
      if(Constant.devMode) print('==== failed to delete: $e');
      showSnackBar(context: state.context, message: 'Failed to delete! Sign out and Sign in again to get the updated list',);
    }
  
  }
}