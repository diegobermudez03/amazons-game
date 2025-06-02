import 'dart:io';

import 'package:flutter/foundation.dart';

const animationDuration = Duration(milliseconds: 500);

String getAsset(String name){
  /*if (kIsWeb) {
    return 'assets/$name';
  } else if (Platform.isAndroid) {
    return 'assets/$name';
  }*/
  return 'assets/$name';
}