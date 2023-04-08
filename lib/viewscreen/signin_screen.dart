// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lesson4/controller/auth_controller.dart';
import 'package:lesson4/model/constants.dart';
import 'package:lesson4/model/signin_screen_model.dart';
import 'package:lesson4/viewscreen/view/view_util.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SignInState();
  }
}

class _SignInState extends State<SignInScreen> {
  late _Controller con;
  late SignInScreenModel screenModel;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    screenModel = SignInScreenModel();
  }

  void render(fn) => setState(fn);
  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: screenModel.isSignInUnderway
          ? const Center(child: CircularProgressIndicator())
          : signInForm(),
    );
  }

  Widget signInForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'PhotoMemo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Email address',
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: screenModel.validateEmail,
                onSaved: screenModel.saveEmail,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
                autocorrect: false,
                obscureText: true,
                validator: screenModel.validatePassword,
                onSaved: screenModel.savePassword,
              ),
              ElevatedButton(
                onPressed: con.signIn,
                child: Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controller {
  _SignInState state;
  _Controller(this.state);

  Future<void> signIn() async {
    FormState? currentState = state.formKey.currentState;
    if (currentState == null) return;
    if (!currentState.validate()) return;
    currentState.save();

    state.render(() {
        state.screenModel.isSignInUnderway = true;
    });

    try {
      await Auth.signIn(
        email: state.screenModel.email!,
        password: state.screenModel.password!,
      );
      // FirebaseAuth.instance.authStateChanged() will be trigger
    } on FirebaseAuthException catch (e) {
      state.render(() => state.screenModel.isSignInUnderway = false);
      var error = 'Sign In Error! Reason: ${e.code} ${e.message ?? ""}';
      if (Constant.devMode) {
        print('========== $error');
      }
      showSnackBar(context: state.context, seconds: 20, message: error);
    } catch (e) {
      state.render(() => state.screenModel.isSignInUnderway = false);
      if (Constant.devMode) {
        print('========== Sign In Error! $e');
      }
      showSnackBar(
          context: state.context, seconds: 20, message: 'Sign In Error: $e');
    }
  }
}
