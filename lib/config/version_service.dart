import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';

class UpdateService {
  static const String apiUrl = ApiConstants.appVersionConfig;

  static Future<void> check(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final info = await PackageInfo.fromPlatform();

      final currentVersion = info.version;

      final minimumVersion = data['minimum_version'];
      final latestVersion = data['latest_version'];

      final forceUpdate = data['force_update'];

      final apkUrl = data['apk_url'];

      if (_isLower(currentVersion, minimumVersion)) {
        _showUpdateDialog(context, apkUrl);
        return;
      }

      if (_isLower(currentVersion, latestVersion) &&
          forceUpdate == true) {
        _showUpdateDialog(context, apkUrl);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static bool _isLower(String current, String target) {
    final currentParts =
    current.split('.').map(int.parse).toList();

    final targetParts =
    target.split('.').map(int.parse).toList();

    for (int i = 0; i < targetParts.length; i++) {
      int currentPart = i < currentParts.length
          ? currentParts[i]
          : 0;

      int targetPart = targetParts[i];

      if (currentPart < targetPart) return true;

      if (currentPart > targetPart) return false;
    }

    return false;
  }

  static void _showUpdateDialog(
      BuildContext context,
      String apkUrl,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
          'Please update the app to continue.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(apkUrl);

              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}