import 'package:flutter/material.dart';
import 'package:lesson4/controller/auth_controller.dart';
import 'package:lesson4/controller/firestore_controller.dart';
import 'package:lesson4/model/constants.dart';
import 'package:lesson4/model/home_screen_model.dart';
import 'package:lesson4/model/photomemo.dart';
import 'package:lesson4/viewscreen/createphotomemo_screen.dart';
import 'package:lesson4/viewscreen/detailview_screen.dart';
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

  void render(fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
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

  Widget bodyView() {
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
        'No PhotoMemo found!',
        style: Theme.of(context).textTheme.titleLarge,
      );
    } else {
      return ListView.builder(
          itemCount: screenModel.photoMemoList!.length,
          itemBuilder: (context, index) {
            PhotoMemo photoMemo = screenModel.photoMemoList![index];
            return ListTile(
              leading: WebImage(
                url: photoMemo.photoURL,
                context: context,
              ),
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
            );
          });
    }
  }

  Widget drawerView() {
    return Drawer(
      child: ListView(
        children: [
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

  Future<void> loadPhotoMemoList() async {
    try {
      state.screenModel.photoMemoList =
          await FirestoreController.getPhotoMemoList(
              email: state.screenModel.user.email!);
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
      state.screenModel.photoMemoList!.insert(0, newMemo);
    });

    void onTap(int index) {
      Navigator.pushNamed(
        state.context,
        DetailViewScreen.routeName,
        arguments: null,
      );
    }
  }
}
