import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../my_home_page.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _acceptedPdpa = false;

  bool _otpSent = false;
  late String _pendingEmail;
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPdpaDialog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyHomePage()),
    );
    if (mounted) {
      setState(() => _acceptedPdpa = true);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedPdpa) {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF0F766E), size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เงื่อนไขการใช้งาน & PDPA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'กรุณาอ่านและยอมรับเงื่อนไขการใช้งาน รวมถึงนโยบายการคุ้มครองข้อมูลส่วนบุคคล (PDPA) ก่อนทำการสมัครสมาชิก',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('อ่านและยอมรับเงื่อนไข'),
            ),
          ],
        ),
      );

      if (result == true) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyHomePage()),
        );
        if (!mounted) return;
        setState(() => _acceptedPdpa = true);
      } else {
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await _api.clearToken();
      await _api.register(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _pendingEmail = _emailCtrl.text.trim();
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ! กรุณากรอกรหัส OTP ที่ส่งไปยังอีเมลของคุณ'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (e.statusCode == 409 || msg.contains('already exists') || msg.contains('มีในระบบ') || msg.contains('ซ้ำ')) {
        // If email already exists, switch to OTP verification step
        setState(() {
          _pendingEmail = _emailCtrl.text.trim();
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.message} — สลับไปหน้ากรอก OTP เพื่อยืนยันยันตัวตน'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('กรุณากรอกรหัส OTP ให้ครบ 6 หลัก'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.verifyOtp(email: _pendingEmail, otp: otp);
      await _api.saveToken(result.token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _loading = true);
    try {
      await _api.resendOtp(email: _pendingEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งรหัส OTP ใหม่เรียบร้อยแล้ว')),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_otpSent ? 'ยืนยันอีเมล' : 'สมัครสมาชิก')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _otpSent ? _buildOtpForm() : _buildRegisterForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'ชื่อ-นามสกุล',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newUsername],
            decoration: const InputDecoration(
              labelText: 'อีเมล',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'รูปแบบอีเมลไม่ถูกต้อง';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
              if (v.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'ยืนยันรหัสผ่าน',
              prefixIcon: Icon(Icons.lock_reset_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v != _passwordCtrl.text ? 'รหัสผ่านไม่ตรงกัน' : null,
            onFieldSubmitted: (_) => _loading ? null : _register(),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showPdpaDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _acceptedPdpa
                    ? const Color(0xFF0F766E).withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptedPdpa
                      ? const Color(0xFF0F766E)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    activeColor: const Color(0xFF0F766E),
                    value: _acceptedPdpa,
                    onChanged: (val) {
                      if (val == true) {
                        _showPdpaDialog();
                      } else {
                        setState(() => _acceptedPdpa = false);
                      }
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                        children: [
                          TextSpan(text: 'ข้าพเจ้าได้อ่านและยอมรับ '),
                          TextSpan(
                            text: 'เงื่อนไขการใช้งาน & นโยบาย PDPA',
                            style: TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _register,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('สมัครสมาชิก'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'เราได้ส่งรหัส OTP 6 หลักไปที่\n$_pendingEmail',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mark_as_unread_outlined,
                  color: Colors.amber.shade900, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📬 หากไม่พบอีเมลในกล่องข้อความหลัก (Inbox)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'กรุณาตรวจสอบในโฟลเดอร์ "จดหมายขยะ" (Spam / Junk) หรือค้นหาชื่อผู้ส่ง "There You Are"',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofocus: true,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(letterSpacing: 12, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _loading ? null : _verifyOtp(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _verifyOtp,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ยืนยัน'),
        ),
        TextButton(
          onPressed: _loading ? null : _resendOtp,
          child: const Text('ส่งรหัส OTP ใหม่'),
        ),
      ],
    );
  }
}
