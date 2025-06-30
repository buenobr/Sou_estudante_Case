// =================================================================================
// ARQUIVO 2: lib/ad_helper.dart (CORRIGIDO PARA WEB)
// =================================================================================
import 'dart:io';
import 'package:flutter/foundation.dart'; // <--- NOVO IMPORT

class AdHelper {
  static String get bannerAdUnitId {
    if (kIsWeb) { // <--- NOVO: Verificação para plataforma web
      // Este é um ID de unidade de anúncio de teste para web.
      // Substitua pelo seu ID real quando for para produção.
      return 'ca-app-pub-1425128236805833/6206872544'; // ID de teste de banner
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-1425128236805833/6206872544';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1425128236805833/6206872544';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}