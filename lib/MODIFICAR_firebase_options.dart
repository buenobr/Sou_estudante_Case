// ARQUIVO: lib/firebase_options.dart
// IMPORTANTE: Este arquivo é gerado automaticamente pelo FlutterFire CLI.
// Para configurar seu projeto, rode `flutterfire configure` no terminal.
// Substitua os valores abaixo pelas credenciais do SEU projeto Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- CONFIGURAÇÃO WEB ---
  // Vá para o Console do Firebase -> Configurações do Projeto -> Seus Apps -> App da Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUA_API_KEY_WEB_AQUI',
    appId: 'SEU_APP_ID_WEB_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    authDomain: 'SEU_PROJECT_ID.firebaseapp.com',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    measurementId: 'SEU_MEASUREMENT_ID_WEB_AQUI (Opcional)',
  );

  // --- CONFIGURAÇÃO ANDROID ---
  // Vá para o Console do Firebase -> Configurações do Projeto -> Seus Apps -> App Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SUA_API_KEY_ANDROID_AQUI',
    appId: 'SEU_APP_ID_ANDROID_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
  );

  // --- CONFIGURAÇÃO IOS ---
  // Vá para o Console do Firebase -> Configurações do Projeto -> Seus Apps -> App iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUA_API_KEY_IOS_AQUI',
    appId: 'SEU_APP_ID_IOS_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    iosClientId: 'SEU_IOS_CLIENT_ID_AQUI',
    iosBundleId: 'SEU_IOS_BUNDLE_ID_AQUI',
  );

  // --- CONFIGURAÇÃO MACOS ---
  // Vá para o Console do Firebase -> Configurações do Projeto -> Seus Apps -> App macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'SUA_API_KEY_MACOS_AQUI',
    appId: 'SEU_APP_ID_MACOS_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    iosClientId: 'SEU_IOS_CLIENT_ID_MACOS_AQUI',
    iosBundleId: 'SEU_IOS_BUNDLE_ID_MACOS_AQUI',
  );

  // --- CONFIGURAÇÃO WINDOWS ---
  // Vá para o Console do Firebase -> Configurações do Projeto -> Seus Apps -> App Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'SUA_API_KEY_WINDOWS_AQUI',
    appId: 'SEU_APP_ID_WINDOWS_AQUI',
    messagingSenderId: 'SEU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'SEU_PROJECT_ID_AQUI',
    authDomain: 'SEU_PROJECT_ID.firebaseapp.com',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    measurementId: 'SEU_MEASUREMENT_ID_WINDOWS_AQUI (Opcional)',
  );
}

