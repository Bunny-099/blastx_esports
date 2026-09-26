import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class GameLauncherService {
  static const String freeFirePackage = 'com.dts.freefireth';
  static const String freeFireMaxPackage = 'com.dts.freefiremax';

  /// Checks if Free Fire or Free Fire MAX is installed or launchable on the device
  Future<bool> isGameInstalled({String packageName = freeFirePackage}) async {
    if (kIsWeb) return false;

    try {
      // 1. Try checking standard android-app URI scheme
      final uriStandard = Uri.parse('android-app://$packageName');
      if (await canLaunchUrl(uriStandard)) {
        return true;
      }

      // 2. Try checking intent scheme for package
      final uriIntent = Uri.parse('intent://#Intent;package=$packageName;end');
      if (await canLaunchUrl(uriIntent)) {
        return true;
      }

      // 3. Try Free Fire MAX if checking main Free Fire package
      if (packageName == freeFirePackage) {
        final uriMax = Uri.parse('android-app://$freeFireMaxPackage');
        if (await canLaunchUrl(uriMax)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('GameLauncherService check error: $e');
      return false;
    }
  }

  /// Launches the game package via intent or custom URL scheme
  Future<bool> launchGame({String packageName = freeFirePackage}) async {
    try {
      // Try intent launch on Android
      final Uri intentUri = Uri.parse('intent://#Intent;package=$packageName;end');
      if (await canLaunchUrl(intentUri)) {
        return await launchUrl(intentUri, mode: LaunchMode.externalApplication);
      }

      // Fallback: try android-app URI
      final Uri appUri = Uri.parse('android-app://$packageName');
      if (await canLaunchUrl(appUri)) {
        return await launchUrl(appUri, mode: LaunchMode.externalApplication);
      }

      // Try Free Fire MAX fallback if main fails
      if (packageName == freeFirePackage) {
        final Uri maxUri = Uri.parse('intent://#Intent;package=$freeFireMaxPackage;end');
        if (await canLaunchUrl(maxUri)) {
          return await launchUrl(maxUri, mode: LaunchMode.externalApplication);
        }
      }

      return false;
    } catch (e) {
      print('GameLauncherService launch error: $e');
      return false;
    }
  }
}
