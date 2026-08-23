import 'package:flutter/material.dart';

import '../services/permission_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// หน้าก่อนเข้าสู่ระบบ (Welcome / Landing Screen)
/// ชื่อแอปพลิเคชัน: There You Are
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================
                  // 1. HERO SECTION (โลโก้ + ชื่อแอป + คำโปรย)
                  // ==========================================
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'There You Are',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'บันทึกและแชร์พิกัดสถานที่ของคุณได้ทุกที่ ทุกเวลา\nเชื่อมต่อทุกความทรงจำในทุกการเดินทาง',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ==========================================
                  // 2. FEATURE HIGHLIGHTS (ฟีเจอร์เด่นของแอป)
                  // ==========================================
                  const _FeatureCard(
                    icon: Icons.my_location_rounded,
                    iconColor: Colors.deepPurple,
                    title: 'Check-in แม่นยำ',
                    subtitle:
                        'บันทึกพิกัด Latitude & Longitude พร้อมรูปภาพความประทับใจ',
                  ),
                  const SizedBox(height: 12),
                  const _FeatureCard(
                    icon: Icons.shield_outlined,
                    iconColor: Color(0xFF10B981),
                    title: 'ปลอดภัยด้วยระบบ OTP',
                    subtitle: 'ยืนยันตัวตนผ่านอีเมลด้วยรหัส OTP 6 หลัก',
                  ),
                  const SizedBox(height: 12),
                  const _FeatureCard(
                    icon: Icons.explore_outlined,
                    iconColor: Colors.amber,
                    title: 'สำรวจ Feed สาธารณะ',
                    subtitle: 'ดูสถานที่ยอดฮิตที่มีคนเช็คอินไว้แบบ Real-time',
                  ),

                  const SizedBox(height: 32),

                  // ==========================================
                  // 3. PERMISSION BUTTON (ขอสิทธิ์ใช้อุปกรณ์)
                  // ==========================================
                  OutlinedButton.icon(
                    onPressed: () =>
                        PermissionService.showPermissionDialog(context),
                    icon: const Icon(Icons.security_rounded, size: 18),
                    label: const Text('ขออนุญาตสิทธิ์อุปกรณ์ (Location & Camera)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      side: BorderSide(color: theme.colorScheme.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==========================================
                  // 4. ACTION BUTTONS (เข้าสู่ระบบ / สมัครสมาชิก)
                  // ==========================================
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded),
                        SizedBox(width: 8),
                        Text(
                          'เข้าสู่ระบบ (Login)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined),
                        SizedBox(width: 8),
                        Text(
                          'สมัครสมาชิกใหม่ (Register)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'There You Are v1.0.0 • Powered by Next.js & Flutter',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
