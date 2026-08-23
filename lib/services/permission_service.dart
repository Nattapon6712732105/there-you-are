import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request Location Permission
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  /// Request Camera Permission
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  /// Request Storage / Photos Permission
  static Future<bool> requestPhotosPermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }
    return status.isGranted;
  }

  /// Show interactive Permission Request Dialog to the user
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.deepPurple, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ขออนุมัติการใช้งานสิทธิ์อุปกรณ์',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แอปพลิเคชัน "There You Are" มีความจำเป็นต้องขออนุญาตเข้าถึงสิทธิ์การใช้งานดังต่อไปนี้ เพื่อให้ทำงานได้อย่างสมบูรณ์:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            _PermissionItem(
              icon: Icons.my_location_rounded,
              color: Colors.blue,
              title: 'พิกัดตำแหน่ง (Location)',
              subtitle: 'เพื่อบันทึกพิกัด Latitude & Longitude ของคุณเมื่อเช็คอิน',
            ),
            SizedBox(height: 10),
            _PermissionItem(
              icon: Icons.camera_alt_rounded,
              color: Color(0xFF10B981),
              title: 'กล้องถ่ายรูป (Camera)',
              subtitle: 'เพื่อถ่ายภาพสถานที่เมื่อทำการเช็คอินสด',
            ),
            SizedBox(height: 10),
            _PermissionItem(
              icon: Icons.photo_library_rounded,
              color: Colors.amber,
              title: 'คลังภาพ (Photos & Storage)',
              subtitle: 'เพื่อเลือกและอัปโหลดรูปภาพสถานที่จากเครื่องของคุณ',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ข้ามไปก่อน'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('อนุญาตสิทธิ์'),
          ),
        ],
      ),
    );

    if (result == true) {
      final statuses = await [
        Permission.location,
        Permission.camera,
        Permission.photos,
      ].request();

      final allGranted = statuses.values.any((s) => s.isGranted);
      return allGranted;
    }
    return false;
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PermissionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
