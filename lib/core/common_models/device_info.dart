import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';


class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<Map<String, String>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      return {
        'platform': 'android',
        'model': androidInfo.model ?? 'unknown',
        'version': androidInfo.version.release ?? 'unknown',
        'deviceId': androidInfo.id ?? 'unknown',
      };
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
      return {
        'platform': 'ios',
        'model': iosInfo.utsname.machine ?? 'unknown',
        'version': iosInfo.systemVersion ?? 'unknown',
        'deviceId': iosInfo.identifierForVendor ?? 'unknown',
      };
    } else {
      return {
        'platform': 'unknown',
        'model': 'unknown',
        'version': 'unknown',
        'deviceId': 'unknown',
      };
    }
  }
}
