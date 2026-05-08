import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ------------------------
// Media conversion helpers
// ------------------------
Future<Map<String, dynamic>> convertImageToBase64(String filePath) async {
  final compressed = await FlutterImageCompress.compressWithFile(
    filePath,
    quality: 40, // lower for big images
    minWidth: 1024,
    minHeight: 1024,
  );

  if (compressed == null) {
    throw "Failed to compress image: $filePath";
  }

  return {
    "filename": filePath.split('/').last,
    "data": base64Encode(compressed),
  };
}

Future<Map<String, dynamic>> convertVideoToBase64(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();

  return {
    "filename": filePath.split('/').last,
    "data": base64Encode(bytes),
    "type": "video",
  };
}