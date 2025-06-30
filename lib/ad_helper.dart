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
      return 'ca-app-pub-3940256099942544/6300978111'; // ID de teste de banner
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}