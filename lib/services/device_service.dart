import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceDetails {
  final String platformName;
  final String modelName;
  final IconData icon;
  final Color color;

  const DeviceDetails({
    required this.platformName,
    required this.modelName,
    required this.icon,
    required this.color,
  });
}

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<DeviceDetails> getDeviceDetails() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        final browserName = webInfo.browserName.name.toUpperCase();
        return DeviceDetails(
          platformName: 'Web',
          modelName: '$browserName Browser (${webInfo.platform ?? 'Web'})',
          icon: Icons.language_rounded,
          color: Colors.blueAccent,
        );
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final brand = androidInfo.brand.isNotEmpty
            ? '${androidInfo.brand[0].toUpperCase()}${androidInfo.brand.substring(1)}'
            : 'Android';
        final model = androidInfo.model;
        return DeviceDetails(
          platformName: 'Android',
          modelName: '$brand $model (Android ${androidInfo.version.release})',
          icon: Icons.android_rounded,
          color: const Color(0xFF3DDC84),
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return DeviceDetails(
          platformName: 'iOS',
          modelName: '${iosInfo.name} (${iosInfo.systemVersion})',
          icon: Icons.phone_iphone_rounded,
          color: Colors.lightBlueAccent,
        );
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return DeviceDetails(
          platformName: 'Linux',
          modelName: linuxInfo.prettyName.isNotEmpty
              ? linuxInfo.prettyName
              : 'Linux Desktop',
          icon: Icons.terminal_rounded,
          color: Colors.orangeAccent,
        );
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return DeviceDetails(
          platformName: 'macOS',
          modelName: macInfo.computerName.isNotEmpty
              ? macInfo.computerName
              : 'Mac Workstation',
          icon: Icons.desktop_mac_rounded,
          color: Colors.purpleAccent,
        );
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfo.windowsInfo;
        return DeviceDetails(
          platformName: 'Windows',
          modelName: winInfo.productName.isNotEmpty
              ? winInfo.productName
              : 'Windows PC',
          icon: Icons.window_rounded,
          color: Colors.lightBlue,
        );
      }
    } catch (e) {
      debugPrint('[DeviceService] Error getting device info: $e');
    }

    return const DeviceDetails(
      platformName: 'Device',
      modelName: 'อุปกรณ์ทั่วไป',
      icon: Icons.devices_rounded,
      color: Colors.grey,
    );
  }
}
