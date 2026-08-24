import 'package:flutter/material.dart';

/// หน้าแสดงนโยบาย PDPA และเงื่อนไขการใช้งาน (Terms of Service & PDPA Compliance Report)
/// สอดคล้องตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562
class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({
    super.key,
    this.title = 'เงื่อนไขการใช้งาน & นโยบาย PDPA',
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isAccepted = false;
  DateTime? _acceptedAt;

  void _toggleAcceptance(bool? value) {
    setState(() {
      _isAccepted = value ?? false;
      if (_isAccepted) {
        _acceptedAt = DateTime.now();
      } else {
        _acceptedAt = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==========================================
                        // HEADER PDPA REPORT BANNER
                        // ==========================================
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF047857)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'รายงานและนโยบายความเป็นส่วนตัว',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Personal Data Protection Act (PDPA Compliance)',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: const Text(
                                  '🛡️ สอดคล้องตาม พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ==========================================
                        // SECTION 1: PURPOSE OF DATA COLLECTION
                        // ==========================================
                        _buildSectionCard(
                          context,
                          title: '1. วัตถุประสงค์ในการเก็บรวบรวมข้อมูลส่วนบุคคล',
                          icon: Icons.assignment_outlined,
                          children: [
                            const Text(
                              'แอปพลิเคชัน "There You Are" มีความจำเป็นต้องเก็บรวบรวม ใช้ และประมวลผลข้อมูลส่วนบุคคลของท่าน เพื่อการให้บริการตามวัตถุประสงค์ดังต่อไปนี้:',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            _buildBulletItem(
                              'ข้อมูลบัญชีผู้ใช้:',
                              'อีเมล, ชื่อ-นามสกุล, รูปโปรไฟล์ สำหรับใช้ในการลงทะเบียน ยืนยันตัวตน (OTP) และจัดการสิทธิ์เข้าใช้งานระบบ',
                            ),
                            _buildBulletItem(
                              'ข้อมูลพิกัดสถานที่ (GPS Location):',
                              'ตำแหน่ง Latitude และ Longitude ที่ท่านเลือกบันทึก เช็คอิน เพื่อการระบุตำแหน่งบนแผนที่และแชร์ความทรงจำ',
                            ),
                            _buildBulletItem(
                              'ข้อมูลทางเทคนิคของอุปกรณ์:',
                              'ระบบปฏิบัติการ (OS), รุ่นอุปกรณ์ และสถานะการเชื่อมต่อ เพื่อใช้ในการปรับปรุงประสิทธิภาพและรักษาความปลอดภัยของระบบ',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ==========================================
                        // SECTION 2: DATA USAGE & DISCLOSURE
                        // ==========================================
                        _buildSectionCard(
                          context,
                          title: '2. การใช้และการเปิดเผยข้อมูลส่วนบุคคล',
                          icon: Icons.share_outlined,
                          children: [
                            const Text(
                              '• ข้อมูลที่ท่านบันทึกและเลือกแชร์เป็นสาธารณะ (Check-in Feed) จะถูกแสดงผลในระบบเพื่อให้ผู้ใช้ท่านอื่นสามารถรับชมตำแหน่งสถานที่ได้\n'
                              '• บริษัท/ผู้พัฒนา จะไม่นำข้อมูลส่วนบุคคลของท่านไปขาย เผยแพร่ หรือส่งต่อให้แก่บุคคลภายนอกโดยเด็ดขาด เว้นแต่ได้รับความยินยอมจากท่าน หรือเป็นกรณีปฏิบัติตามคำสั่งของเจ้าหน้าที่ตามกฎหมาย',
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ==========================================
                        // SECTION 3: DATA SUBJECT RIGHTS (PDPA RIGHTS)
                        // ==========================================
                        _buildSectionCard(
                          context,
                          title: '3. สิทธิของเจ้าของข้อมูลส่วนบุคคลตามกฎหมาย PDPA',
                          icon: Icons.gavel_outlined,
                          children: [
                            const Text(
                              'ท่านมีสิทธิตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 ดังต่อไปนี้:',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            _buildRightBadge(
                              Icons.visibility_outlined,
                              'สิทธิในการเข้าถึงข้อมูล (Right of Access)',
                              'สามารถเรียกดูและขอรับสำเนาข้อมูลส่วนบุคคลของท่านในระบบได้ตลอดเวลา',
                            ),
                            _buildRightBadge(
                              Icons.edit_note_outlined,
                              'สิทธิในการแก้ไขข้อมูล (Right to Rectification)',
                              'สามารถแก้ไขข้อมูลชื่อ หรือเปลี่ยนรหัสผ่านได้ผ่านเมนูแก้ไขโปรไฟล์',
                            ),
                            _buildRightBadge(
                              Icons.delete_forever_outlined,
                              'สิทธิในการลบข้อมูล (Right to Erasure / Right to be Forgotten)',
                              'ท่านสามารถใช้สิทธิลบบัญชีผู้ใช้และข้อมูลทั้งหมดออกจากระบบอย่างถาวรได้ทันทีผ่านเมนู "ลบบัญชีผู้ใช้ถาวร"',
                            ),
                            _buildRightBadge(
                              Icons.cancel_outlined,
                              'สิทธิในการถอนความยินยอม (Right to Withdraw Consent)',
                              'ท่านสามารถถอนความยินยอมในการเก็บรวบรวมข้อมูลได้ทุกเมื่อ',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ==========================================
                        // SECTION 4: TERMS OF SERVICE
                        // ==========================================
                        _buildSectionCard(
                          context,
                          title: '4. เงื่อนไขและข้อตกลงการใช้งาน (Terms of Service)',
                          icon: Icons.rule_outlined,
                          children: [
                            const Text(
                              '1. ผู้ใช้บริการต้องให้ข้อมูลที่เป็นความจริงในการลงทะเบียนบัญชีผู้ใช้\n'
                              '2. ผู้ใช้บริการต้องไม่บันทึก ปักหมุด หรือแชร์เนื้อหาที่ไม่เหมาะสม ละเมิดสิทธิผู้อื่น หรือขัดต่อศีลธรรมอันดี\n'
                              '3. ผู้พัฒนาขอสงวนสิทธิ์ในการระงับบัญชีผู้ใช้หากพบการใช้งานที่ละเมิดข้อตกลงโดยไม่ต้องแจ้งให้ทราบล่วงหน้า',
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ==========================================
                        // CONSENT ACKNOWLEDGMENT & TIMESTAMP
                        // ==========================================
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isAccepted
                                  ? primaryColor
                                  : Colors.grey.shade300,
                              width: _isAccepted ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                activeColor: primaryColor,
                                value: _isAccepted,
                                onChanged: _toggleAcceptance,
                                title: const Text(
                                  'ข้าพเจ้าได้อ่าน เข้าใจ และยอมรับเงื่อนไขการใช้งาน รวมถึงยินยอมให้เก็บรวบรวม ใช้ และเปิดเผยข้อมูลส่วนบุคคลตามกฎหมาย PDPA',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'การติ๊กเครื่องหมายเป็นการยืนยันความยินยอมทางอิเล็กทรอนิกส์',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              if (_acceptedAt != null) ...[
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.green, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'บันทึกการยินยอมเมื่อ: ${_acceptedAt!.day}/${_acceptedAt!.month}/${_acceptedAt!.year} ${_acceptedAt!.hour.toString().padLeft(2, '0')}:${_acceptedAt!.minute.toString().padLeft(2, '0')} น.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('ย้อนกลับ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isAccepted
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'บันทึกความยินยอม PDPA เรียบร้อยแล้ว'),
                                    ),
                                  );
                                  Navigator.of(context).maybePop();
                                }
                              : null,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('ยอมรับเงื่อนไข'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    const primaryColor = Color(0xFF0F766E);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightBadge(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F766E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
