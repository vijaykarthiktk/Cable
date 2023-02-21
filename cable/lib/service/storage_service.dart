import 'dart:io';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
class Storage{
  final FirebaseStorage storage = FirebaseStorage.instance;
  uploadFile(String fileName, String filePath) async {
    File file = File(filePath);
    try{
      await storage.ref('test/$fileName').putFile(file);
    } on FirebaseException catch (e){
      if (kDebugMode) {
        print(e);
      }
    }
  }
}