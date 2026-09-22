import 'dart:convert';
import 'package:flutter/services.dart';

class StickerLoader {
  static Future<List<String>> loadStickers() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> map = json.decode(manifest);

    return map.keys
        .where((path) =>
            path.startsWith('assets/fee/sticker/') &&
            path.endsWith('.png'))
        .toList();
  }
}
