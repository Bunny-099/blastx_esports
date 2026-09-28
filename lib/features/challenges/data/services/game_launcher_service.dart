import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class GameLauncherService {
  static const String freeFirePackage = 'com.dts.freefireth';
  static const String freeFireMaxPackage = 'com.dts.freefiremax';

  static const MethodChannel _channel = MethodChannel('com.blastix.esports/game_launcher');

  /// Helper to build proper Android launcher intent URI for url_launcher fallback
  Uri _buildLaunchUri(String packageName) {
    return Uri.parse(
      'intent:#Intent;action=android.intent.action.MAIN;category=android.intent.category.LAUNCHER;package=$packageName;end',
    );
  }

  /// Native check if package is installed on Android
  Future<bool> _nativeCheckInstalled(String packageName) async {
    if (kIsWeb) return false;
    try {
      final bool? isInstalled = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': packageName},
      );
      if (isInstalled != null) return isInstalled;
    } catch (e) {
      debugPrint('Native package check exception: $e');
    }

    // Fallback check using url_launcher
    try {
      final Uri intentUri = _buildLaunchUri(packageName);
      return await canLaunchUrl(intentUri);
    } catch (e) {
      debugPrint('Fallback check error: $e');
      return false;
    }
  }

  /// Native launch of package on Android
  Future<bool> _nativeLaunchPackage(String packageName) async {
    if (kIsWeb) return false;
    try {
      final bool? launched = await _channel.invokeMethod<bool>(
        'launchPackage',
        {'packageName': packageName},
      );
      if (launched == true) return true;
    } catch (e) {
      debugPrint('Native package launch exception: $e');
    }

    // Fallback launch using url_launcher
    try {
      final Uri intentUri = _buildLaunchUri(packageName);
      return await launchUrl(intentUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Fallback launch error: $e');
      return false;
    }
  }

  /// Returns the installed Free Fire package name (MAX or Standard), or null if neither is installed.
  Future<String?> getInstalledPackageName({String? preferredPackage}) async {
    if (kIsWeb) return null;

    final packagesToCheck = <String>[];
    if (preferredPackage != null && preferredPackage.isNotEmpty) {
      packagesToCheck.add(preferredPackage);
    }
    if (!packagesToCheck.contains(freeFireMaxPackage)) {
      packagesToCheck.add(freeFireMaxPackage);
    }
    if (!packagesToCheck.contains(freeFirePackage)) {
      packagesToCheck.add(freeFirePackage);
    }

    for (final pkg in packagesToCheck) {
      final installed = await _nativeCheckInstalled(pkg);
      if (installed) {
        return pkg;
      }
    }

    return null;
  }

  /// Checks if Free Fire or Free Fire MAX is installed
  Future<bool> isGameInstalled({String packageName = freeFirePackage}) async {
    final installedPkg = await getInstalledPackageName(preferredPackage: packageName);
    return installedPkg != null;
  }

  /// Launches the installed Free Fire game package
  Future<bool> launchGame({String packageName = freeFirePackage}) async {
    final String? installedPkg = await getInstalledPackageName(preferredPackage: packageName);

    if (installedPkg != null) {
      return await _nativeLaunchPackage(installedPkg);
    }

    return false;
  }

  /// Opens the Free Fire MAX page on Google Play Store (available in India / global)
  Future<bool> openPlayStoreForFreeFire() async {
    try {
      final Uri marketUri = Uri.parse('market://details?id=$freeFireMaxPackage');
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
      final Uri webUri = Uri.parse('https://play.google.com/store/apps/details?id=$freeFireMaxPackage');
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
      return false;
    }
  }
}
