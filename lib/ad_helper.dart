import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (kIsWeb) {
      return 'ca-app-pub-1425128236805833/6206872544';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-1425128236805833/6206872544';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1425128236805833/6206872544';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
