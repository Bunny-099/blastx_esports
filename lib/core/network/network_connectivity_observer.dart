import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Observer that periodically checks for internet reachability.
/// Uses a lightweight lookup to ensure network interface is active and online.
class NetworkConnectivityObserver {
  static final NetworkConnectivityObserver _instance = NetworkConnectivityObserver._internal();
  factory NetworkConnectivityObserver() => _instance;
  NetworkConnectivityObserver._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Checks internet connectivity by looking up a fast reliable host.
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isOnline = true;
        return true;
      }
    } catch (e) {
      debugPrint('NetworkConnectivityObserver: Offline check triggered - $e');
      _isOnline = false;
      return false;
    }
    _isOnline = false;
    return false;
  }
}
