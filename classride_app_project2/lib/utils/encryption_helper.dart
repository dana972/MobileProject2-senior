import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  static final _key = Key.fromUtf8('Ks93!jsL04@xCj8VtQzY2wMa12345678');
  // ✅ 32 characters
  static final _iv = IV.fromLength(16);

  static String encryptMessage(String message) {
    final encrypter = Encrypter(AES(_key));
    return encrypter.encrypt(message, iv: _iv).base64;
  }

  static String decryptMessage(String encrypted) {
    final encrypter = Encrypter(AES(_key));
    return encrypter.decrypt(Encrypted.fromBase64(encrypted), iv: _iv);
  }
}
