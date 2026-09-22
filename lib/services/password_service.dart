import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordService {
  PasswordService._();

  static String hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
