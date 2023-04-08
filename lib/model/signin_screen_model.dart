class SignInScreenModel {
  String? email;
  String? password;
  bool isSignInUnderway = false;

  String? validateEmail(String? value) {
    if (value == null) {
      return 'No email provided';
    } else if (!(value.contains('@') && value.contains('.'))) {
      return 'Invalid email format';
    } else {
      return null;
    }
  }

  String? validatePassword(String? value) {
    if (value == null) {
      return 'password not provided';
    } else if (value.length < 6) {
      return 'password too short';
    } else {
      return null;
    }
  }

  void saveEmail(String? value) {
    if (value != null) {
      email = value;
    }
  }

  void savePassword(String? value) {
    if (value != null) {
      password = value;
    }
  }
}