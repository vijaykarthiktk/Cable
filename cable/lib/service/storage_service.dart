import 'dart:io';

import 'package:cached_firestorage/cached_firestorage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
class Storage{
  final FirebaseStorage storage = FirebaseStorage.instance;
  final CachedFirestorage cacheStorage = CachedFirestorage.instance;
  uploadFileCable(String fileName, String filePath, bool isCable) async {
    File file = File(filePath);
    try{
      if(isCable){
        print("cable");
        await storage.ref('cable/$fileName').putFile(file);
      }else{
        await storage.ref('internet/$fileName').putFile(file);
      }
    } on FirebaseException catch (e){
      if (kDebugMode) {
        print(e);
      }
    }
  }

}