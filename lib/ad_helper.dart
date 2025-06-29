// =================================================================================
// 2. NOVO ARQUIVO: lib/ad_helper.dart
// =================================================================================
// Este arquivo ajuda a gerenciar os IDs dos anúncios.
import 'dart:io';

class AdHelper {
  // Use os IDs de teste do AdMob para não violar as políticas durante o desenvolvimento.
  // TROQUE PELOS SEUS IDs REAIS QUANDO FOR PUBLICAR O APP.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // ID de teste do Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // ID de teste do iOS
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
