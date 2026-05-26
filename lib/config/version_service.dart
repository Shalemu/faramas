import 'dart:convert';
import 'dart:io';

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

      final currentVersion = info.version.split('+').first;
      print("Current Version");
      print(currentVersion);

      final minimumVersion = data['minimum_version'];
      final latestVersion = data['latest_version'];

      print("latestVersion Version");
      print(latestVersion);

      print("minimumVersion Version");
      print(minimumVersion);

      final forceUpdate = data['force_update'];

      final androidUrl = data['android_apk_url'];
      final iosUrl = data['apple_apk_url'];
      final message = data['message'];

      String? updateUrl;
      if (Platform.isAndroid) {
        updateUrl = androidUrl;
      } else if (Platform.isIOS) {
        updateUrl = iosUrl;
      }

      if (_isLower(currentVersion, minimumVersion)) {
        _showUpdateDialog(context, updateUrl, message);
        return;
      }

      if (_isLower(currentVersion, latestVersion) &&
          forceUpdate == true) {
        _showUpdateDialog(context, updateUrl, message);
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
      String? apkUrl,
      String message,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevents user from dismissing via back button
        child: AlertDialog.adaptive(
          icon: const Icon(Icons.update_rounded, size: 40),
          title: const Text('Update Required'),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(apkUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}