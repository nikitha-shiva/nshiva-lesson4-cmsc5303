class CreateAccountScreenModel {
  String? email;
  String? password;
  String? passwordConfirm;
  bool showPasswords = false;

  String? validateEmail(String? value) {
    if (value == null || !(value.contains('@') && value.contains('.'))) {
      return 'Invalid email';
    } else {
      return null;
    }
  }

  String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password to short (min 6 chars)';
    } else {
      return null;
    }
  }

  void saveEmail(String? value) {
    email = value;
  }

  void savePassword(String? value) {
    password = value;
  }

  void savePasswordConfirm(String? value) {
    passwordConfirm = value;
  }
}
