import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class IdCheckerScreen extends StatefulWidget {
  const IdCheckerScreen({super.key});

  @override
  State<IdCheckerScreen> createState() => _IdCheckerScreenState();
}

class _IdCheckerScreenState extends State<IdCheckerScreen> {
  final _controller = TextEditingController();
  _CheckResult? _result;

  void _check() {
    final raw = _controller.text.replaceAll(RegExp(r'[\s\-]'), '');
    if (raw.isEmpty) return;
    setState(() {
      if (RegExp(r'^\d{13}$').hasMatch(raw)) {
        _result = _decodeThaiId(raw);
      } else if (RegExp(r'^(\+66|0)\d{8,9}$').hasMatch(raw)) {
        final norm = raw.startsWith('+66') ? '0${raw.substring(3)}' : raw;
        _result = _decodePhone(norm);
      } else if (RegExp(r'^\d+$').hasMatch(raw)) {
        _result = _CheckResult(
          type: 'ไม่รู้จักรูปแบบ',
          valid: false,
          icon: Icons.help_outline,
          iconColor: AppTheme.warningColor,
          sections: [
            _Section('ข้อมูล', [
              _Row('ตัวเลขที่ป้อน', raw),
              _Row('ความยาว', '${raw.length} หลัก'),
              _Row('รองรับ', '13 หลัก (บัตรประชาชน) หรือ 10 หลัก (เบอร์โทร)'),
            ]),
          ],
        );
      } else {
        _result = _CheckResult(
          type: 'รูปแบบไม่ถูกต้อง',
          valid: false,
          icon: Icons.error_outline,
          iconColor: AppTheme.errorColor,
          sections: [
            _Section('ข้อมูล', [
              _Row('ข้อผิดพลาด', 'กรุณากรอกเฉพาะตัวเลข'),
            ]),
          ],
        );
      }
    });
  }

  _CheckResult _decodeThaiId(String id) {
    // Checksum: digits[0..11] × [13,12,..2], sum, (11 - sum%11) % 10 == digits[12]
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(id[i]) * (13 - i);
    }
    final check = (11 - (sum % 11)) % 10;
    final valid = check == int.parse(id[12]);

    final d1 = int.parse(id[0]);
    final rcode = id.substring(1, 5);
    final province = _rcodeToProvince(rcode);
    final regType = _regType(d1);

    return _CheckResult(
      type: 'เลขบัตรประจำตัวประชาชนไทย',
      valid: valid,
      icon: valid ? Icons.credit_card : Icons.credit_card_off,
      iconColor: valid ? AppTheme.successColor : AppTheme.errorColor,
      sections: [
        _Section('ผลการตรวจสอบ', [
          _Row('Checksum', valid ? '✓ ถูกต้อง' : '✗ ไม่ถูกต้อง'),
          _Row('เลขประจำตัว', id),
        ]),
        _Section('โครงสร้างตัวเลข', [
          _Row('หลักที่ 1 (ประเภท)', '$d1 — $regType'),
          _Row('หลักที่ 2-5 (รหัสสำนักทะเบียน)', rcode),
          _Row('จังหวัด/พื้นที่ (โดยประมาณ)', province),
          _Row('หลักที่ 6-10 (ลำดับ)', id.substring(5, 10)),
          _Row('หลักที่ 11-12 (ลำดับย่อย)', id.substring(10, 12)),
          _Row('หลักที่ 13 (Checksum)', id[12]),
        ]),
        _Section('ข้อจำกัด', [
          _Row('หมายเหตุ',
              'ระบบตรวจสอบได้เพียงโครงสร้างและ Checksum เท่านั้น\nไม่สามารถยืนยันตัวบุคคลได้'),
        ]),
      ],
    );
  }

  _CheckResult _decodePhone(String phone) {
    final prefix2 = phone.substring(0, 2);
    final prefix3 = phone.substring(0, 3);
    final prefix4 = phone.length >= 4 ? phone.substring(0, 4) : '';

    String type = '';
    String carrier = '';
    String note = '';
    bool isMobile = false;

    if (['06', '08', '09'].contains(prefix2)) {
      isMobile = true;
      type = 'โทรศัพท์มือถือ / VoIP';

      // Carrier hints (historical — MNP ทำให้อาจย้ายค่ายได้)
      final mobileMap = {
        '061': 'True Move H (เดิม)', '062': 'True Move H (เดิม)',
        '063': 'True Move H (เดิม)', '064': 'True Move H / MVNO',
        '065': 'True Move H (เดิม)',
        '066': 'MVNO / อื่น ๆ',
        '067': 'MVNO / อื่น ๆ',
        '068': 'MVNO / อื่น ๆ',
        '069': 'MVNO / อื่น ๆ',
        '080': 'AIS (เดิม)', '081': 'AIS (เดิม)',
        '082': 'DTAC (เดิม)', '083': 'DTAC (เดิม)',
        '084': 'DTAC (เดิม)', '085': 'AIS (เดิม)',
        '086': 'AIS (เดิม)', '087': 'DTAC (เดิม)',
        '088': 'True Move H (เดิม)', '089': 'AIS (เดิม)',
        '090': 'DTAC (เดิม)', '091': 'AIS (เดิม)',
        '092': 'DTAC (เดิม)', '093': 'True Move H (เดิม)',
        '094': 'True Move H (เดิม)', '095': 'True Move H (เดิม)',
        '096': 'AIS (เดิม)', '097': 'AIS (เดิม)',
        '098': 'DTAC (เดิม)', '099': 'True Move H / DTAC (เดิม)',
      };
      carrier = mobileMap[prefix3] ?? 'ไม่ทราบ';
      note = 'ข้อมูลค่าย เป็นข้อมูล "ก่อน MNP" เท่านั้น ปัจจุบันอาจย้ายค่ายแล้ว';
    } else if (prefix2 == '02') {
      type = 'โทรศัพท์ประจำที่ — กรุงเทพฯ และปริมณฑล';
    } else if (prefix2 == '03') {
      type = 'โทรศัพท์ประจำที่ — ภาคกลาง/ตะวันออก';
      final areaMap = {
        '032': 'ราชบุรี / สมุทรสาคร', '033': 'ชลบุรี / ระยอง',
        '034': 'นครปฐม / สมุทรสงคราม', '035': 'อยุธยา / อ่างทอง',
        '036': 'ลพบุรี / สระบุรี', '037': 'ปราจีนบุรี / สระแก้ว',
        '038': 'ชลบุรี (พัทยา)', '039': 'จันทบุรี / ตราด',
      };
      carrier = areaMap[prefix3] ?? '';
    } else if (prefix2 == '04') {
      type = 'โทรศัพท์ประจำที่ — ภาคตะวันออกเฉียงเหนือ';
      final areaMap = {
        '042': 'อุดรธานี / หนองคาย', '043': 'ขอนแก่น',
        '044': 'นครราชสีมา / บุรีรัมย์', '045': 'อุบลราชธานี',
      };
      carrier = areaMap[prefix3] ?? '';
    } else if (prefix2 == '05') {
      type = 'โทรศัพท์ประจำที่ — ภาคเหนือ';
      final areaMap = {
        '052': 'เชียงราย', '053': 'เชียงใหม่ / ลำพูน',
        '054': 'แพร่ / น่าน', '055': 'พิษณุโลก / อุตรดิตถ์',
        '056': 'พิจิตร / นครสวรรค์',
      };
      carrier = areaMap[prefix3] ?? '';
    } else if (prefix2 == '07') {
      type = 'โทรศัพท์ประจำที่ — ภาคใต้';
      final areaMap = {
        '073': 'สงขลา / ปัตตานี', '074': 'สงขลา (หาดใหญ่)',
        '075': 'นครศรีธรรมราช', '076': 'ภูเก็ต / พังงา',
        '077': 'สุราษฎร์ธานี', '078': 'ยะลา / นราธิวาส',
      };
      carrier = areaMap[prefix3] ?? '';
    } else {
      type = 'ไม่รู้จักรูปแบบเบอร์โทร';
    }

    final formatted = phone.length == 10
        ? '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}'
        : phone;

    return _CheckResult(
      type: isMobile ? 'เบอร์มือถือ' : 'เบอร์โทรศัพท์',
      valid: true,
      icon: isMobile ? Icons.smartphone : Icons.phone,
      iconColor: AppTheme.primaryColor,
      sections: [
        _Section('ข้อมูลเบอร์โทร', [
          _Row('เบอร์', formatted),
          _Row('ประเภท', type),
          if (carrier.isNotEmpty) _Row(isMobile ? 'ค่าย (เดิม)' : 'พื้นที่', carrier),
          if (note.isNotEmpty) _Row('หมายเหตุ', note),
        ]),
        _Section('โครงสร้าง', [
          _Row('Prefix 2 หลัก', prefix2),
          _Row('Prefix 3 หลัก', prefix3),
          if (prefix4.isNotEmpty) _Row('Prefix 4 หลัก', prefix4),
          _Row('ความยาว', '${phone.length} หลัก'),
        ]),
      ],
    );
  }

  String _regType(int d) {
    const map = {
      1: 'บุคคลที่ได้รับสัญชาติไทย (เกิดในประเทศ)',
      2: 'บุคคลที่ได้รับสัญชาติไทย (เกิดต่างประเทศ)',
      3: 'คนไทย (แจ้งเกิดเกินกำหนด)',
      4: 'บุคคลที่ได้รับอนุญาตให้อยู่ชั่วคราว',
      5: 'บุคคลที่ได้รับอนุญาตให้อยู่ถาวร',
      6: 'ผู้ที่เข้าเมืองโดยไม่ชอบด้วยกฎหมาย',
      7: 'บุตรของบุคคลประเภท 6',
      8: 'คนต่างด้าว (อาศัยในประเทศนาน)',
      0: 'บุคคลไม่มีสถานะทางทะเบียน',
    };
    return map[d] ?? 'ไม่ทราบประเภท';
  }

  String _rcodeToProvince(String rcode) {
    final code = int.tryParse(rcode) ?? 0;
    if (code == 0) return 'ไม่ทราบ';

    // Simplified mapping by rcode range
    // Full rcode.json จาก BORA ต้องดาวน์โหลดแยก
    const ranges = [
      (1000, 1099, 'กรุงเทพมหานคร'),
      (1100, 1199, 'สมุทรปราการ'),
      (1200, 1299, 'นนทบุรี'),
      (1300, 1399, 'ปทุมธานี'),
      (1400, 1499, 'พระนครศรีอยุธยา'),
      (1500, 1599, 'อ่างทอง'),
      (1600, 1699, 'ลพบุรี'),
      (1700, 1799, 'สิงห์บุรี'),
      (1800, 1899, 'ชัยนาท'),
      (1900, 1999, 'สระบุรี'),
      (2000, 2099, 'ชลบุรี'),
      (2100, 2199, 'ระยอง'),
      (2200, 2299, 'จันทบุรี'),
      (2300, 2399, 'ตราด'),
      (2400, 2499, 'ฉะเชิงเทรา'),
      (2500, 2599, 'ปราจีนบุรี'),
      (2600, 2699, 'นครนายก'),
      (2700, 2799, 'สระแก้ว'),
      (3000, 3099, 'นครราชสีมา'),
      (3100, 3199, 'บุรีรัมย์'),
      (3200, 3299, 'สุรินทร์'),
      (3300, 3399, 'ศรีสะเกษ'),
      (3400, 3499, 'อุบลราชธานี'),
      (3500, 3599, 'ยโสธร'),
      (3600, 3699, 'ชัยภูมิ'),
      (3700, 3799, 'อำนาจเจริญ'),
      (3800, 3899, 'บึงกาฬ'),
      (3900, 3999, 'หนองบัวลำภู'),
      (4000, 4099, 'ขอนแก่น'),
      (4100, 4199, 'อุดรธานี'),
      (4200, 4299, 'เลย'),
      (4300, 4399, 'หนองคาย'),
      (4400, 4499, 'มหาสารคาม'),
      (4500, 4599, 'ร้อยเอ็ด'),
      (4600, 4699, 'กาฬสินธุ์'),
      (4700, 4799, 'สกลนคร'),
      (4800, 4899, 'นครพนม'),
      (4900, 4999, 'มุกดาหาร'),
      (5000, 5099, 'เชียงใหม่'),
      (5100, 5199, 'ลำพูน'),
      (5200, 5299, 'ลำปาง'),
      (5300, 5399, 'อุตรดิตถ์'),
      (5400, 5499, 'แพร่'),
      (5500, 5599, 'น่าน'),
      (5600, 5699, 'พะเยา'),
      (5700, 5799, 'เชียงราย'),
      (5800, 5899, 'แม่ฮ่องสอน'),
      (6000, 6099, 'นครสวรรค์'),
      (6100, 6199, 'อุทัยธานี'),
      (6200, 6299, 'กำแพงเพชร'),
      (6300, 6399, 'ตาก'),
      (6400, 6499, 'สุโขทัย'),
      (6500, 6599, 'พิษณุโลก'),
      (6600, 6699, 'พิจิตร'),
      (6700, 6799, 'เพชรบูรณ์'),
      (7000, 7099, 'ราชบุรี'),
      (7100, 7199, 'กาญจนบุรี'),
      (7200, 7299, 'สุพรรณบุรี'),
      (7300, 7399, 'นครปฐม'),
      (7400, 7499, 'สมุทรสาคร'),
      (7500, 7599, 'สมุทรสงคราม'),
      (7600, 7699, 'เพชรบุรี'),
      (7700, 7799, 'ประจวบคีรีขันธ์'),
      (8000, 8099, 'นครศรีธรรมราช'),
      (8100, 8199, 'กระบี่'),
      (8200, 8299, 'พังงา'),
      (8300, 8399, 'ภูเก็ต'),
      (8400, 8499, 'สุราษฎร์ธานี'),
      (8500, 8599, 'ระนอง'),
      (8600, 8699, 'ชุมพร'),
      (9000, 9099, 'สงขลา'),
      (9100, 9199, 'สตูล'),
      (9200, 9299, 'ตรัง'),
      (9300, 9399, 'พัทลุง'),
      (9400, 9499, 'ปัตตานี'),
      (9500, 9599, 'ยะลา'),
      (9600, 9699, 'นราธิวาส'),
    ];

    for (final r in ranges) {
      if (code >= r.$1 && code <= r.$2) return r.$3;
    }
    return 'ไม่ทราบ (rcode: $rcode)';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบบัตรประชาชน / เบอร์โทร')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('กรอกเลขบัตรประชาชน 13 หลัก หรือ เบอร์โทร',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\-\+]')),
                    ],
                    maxLength: 16,
                    decoration: const InputDecoration(
                      hintText: 'เช่น 1234567890123 หรือ 0812345678',
                      prefixIcon: Icon(Icons.dialpad),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _check(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('ตรวจสอบ'),
                      onPressed: _check,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null) _buildResult(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(_CheckResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: r.iconColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: r.iconColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(r.icon, color: r.iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.type,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: r.iconColor)),
                    Text(r.valid ? 'ผ่านการตรวจสอบ' : 'ไม่ผ่านการตรวจสอบ',
                        style: TextStyle(
                            fontSize: 13, color: r.iconColor.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sections
        for (final sec in r.sections) ...[
          _buildSection(sec),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildSection(_Section sec) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(sec.title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
          ),
          for (int i = 0; i < sec.rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 14),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(sec.rows[i].label,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    child: Text(sec.rows[i].value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---- Data classes ----
class _CheckResult {
  final String type;
  final bool valid;
  final IconData icon;
  final Color iconColor;
  final List<_Section> sections;
  const _CheckResult({
    required this.type,
    required this.valid,
    required this.icon,
    required this.iconColor,
    required this.sections,
  });
}

class _Section {
  final String title;
  final List<_Row> rows;
  const _Section(this.title, this.rows);
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}
