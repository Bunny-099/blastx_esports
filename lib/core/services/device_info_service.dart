import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoData {
  final String deviceType;  // "ANDROID" or "IOS"
  final String deviceModel; // e.g. "iPhone 15 Pro", "Samsung S24"
  final String osVersion;   // e.g. "iOS 17.5.1", "Android 14"
  final String appVersion;  // e.g. "1.0.0"

  const DeviceInfoData({
    required this.deviceType,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'device_type': deviceType,
    'device_model': deviceModel,
    'os_version': osVersion,
    'app_version': appVersion,
  };

  Map<String, String> toHeaders() => {
    'X-Device-Type': deviceType,
    'X-Device-Model': deviceModel,
    'X-OS-Version': osVersion,
    'X-App-Version': appVersion,
  };
}

class DeviceInfoService {
  DeviceInfoData? _cachedData;

  Future<DeviceInfoData> getDeviceInfo() async {
    if (_cachedData != null) return _cachedData!;

    String deviceType = kIsWeb
        ? 'WEB'
        : Platform.isIOS
            ? 'IOS'
            : Platform.isAndroid
                ? 'ANDROID'
                : 'UNKNOWN';

    String deviceModel = 'Unknown Device';
    String osVersion = 'Unknown OS';
    String appVersion = '1.0.0';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = _formatIosDeviceModel(
          iosInfo.utsname.machine,
          iosInfo.model,
          iosInfo.name,
        );
        osVersion = 'iOS ${iosInfo.systemVersion}';
      } else if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;
        if (manufacturer.isEmpty || model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
          deviceModel = model.isNotEmpty ? model : 'Android Device';
        } else {
          deviceModel = '${manufacturer[0].toUpperCase()}${manufacturer.substring(1)} $model';
        }
        osVersion = 'Android ${androidInfo.version.release}';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      if (!kIsWeb && Platform.isIOS) {
        deviceModel = 'iPhone';
        osVersion = 'iOS';
      } else if (!kIsWeb && Platform.isAndroid) {
        deviceModel = 'Android Device';
        osVersion = 'Android';
      }
    }

    _cachedData = DeviceInfoData(
      deviceType: deviceType,
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
    );

    return _cachedData!;
  }

  bool get isIos => !kIsWeb && Platform.isIOS;

  String _formatIosDeviceModel(String machine, String model, String name) {
    const iosMachineMap = {
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone16,2': 'iPhone 15 Pro Max',
      'iPhone17,1': 'iPhone 16 Pro',
      'iPhone17,2': 'iPhone 16 Pro Max',
      'iPhone17,3': 'iPhone 16',
      'iPhone17,4': 'iPhone 16 Plus',
    };
    if (iosMachineMap.containsKey(machine)) {
      return iosMachineMap[machine]!;
    }
    if (name.isNotEmpty && name != 'iPhone' && name != 'iPad') {
      return name;
    }
    return model.isNotEmpty ? model : 'iPhone';
  }
}
