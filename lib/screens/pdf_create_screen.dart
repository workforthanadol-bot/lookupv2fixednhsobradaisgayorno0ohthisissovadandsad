import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/candidate.dart';
import '../providers/search_provider.dart';
import '../theme/app_theme.dart';
import '../database/db_helper.dart';

/// PDF document type enum
enum PdfDocType { examReport, applicationLetter, infoSummary }
enum PdfPageSize { a4, a5 }

class PdfCreateScreen extends ConsumerStatefulWidget {
  /// Pre-selected candidates (e.g., from detail screen).
  /// If null, user picks from search results.
  final List<Candidate>? candidates;

  const PdfCreateScreen({super.key, this.candidates});

  @override
  ConsumerState<PdfCreateScreen> createState() => _PdfCreateScreenState();
}

class _PdfCreateScreenState extends ConsumerState<PdfCreateScreen> {
  PdfDocType _docType = PdfDocType.examReport;
  PdfPageSize _pageSize = PdfPageSize.a4;
  bool _generating = false;

  List<Candidate> get _candidates {
    if (widget.candidates != null && widget.candidates!.isNotEmpty) {
      return widget.candidates!;
    }
    return ref.read(selectedCandidatesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.candidates != null
        ? widget.candidates!.length
        : ref.watch(selectedCandidatesProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('สร้างเอกสาร PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Candidate count banner ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'ผู้สมัครที่เลือก: $selectedCount คน',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (widget.candidates == null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showSelectDialog(context),
                      child: const Text('เลือก'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Document type ----
            _SectionHeader(title: 'เลือกประเภทเอกสาร'),
            const SizedBox(height: 10),
            _RadioCard(
              value: PdfDocType.examReport,
              groupValue: _docType,
              title: 'ใบรายงานผลการสอบ',
              subtitle: 'แสดงข้อมูลผู้สมัคร และผลคะแนน',
              onChanged: (v) => setState(() => _docType = v!),
            ),
            const SizedBox(height: 8),
            _RadioCard(
              value: PdfDocType.applicationLetter,
              groupValue: _docType,
              title: 'หนังสือรับรองการสมัคร',
              subtitle: 'สำหรับยื่นต่อหน่วยงาน',
              onChanged: (v) => setState(() => _docType = v!),
            ),
            const SizedBox(height: 8),
            _RadioCard(
              value: PdfDocType.infoSummary,
              groupValue: _docType,
              title: 'เอกสารรวมข้อมูลผู้สมัคร',
              subtitle: 'รวมข้อมูลทั้งหมดในรูปแบบราชการ',
              onChanged: (v) => setState(() => _docType = v!),
            ),
            const SizedBox(height: 20),

            // ---- Page size ----
            _SectionHeader(title: 'รูปแบบเอกสาร'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SizeCard(
                    label: 'แบบมาตรฐาน (A4)',
                    sub: 'ตามรูปแบบราชการ',
                    selected: _pageSize == PdfPageSize.a4,
                    onTap: () => setState(() => _pageSize = PdfPageSize.a4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SizeCard(
                    label: 'แบบย่อ (A5)',
                    sub: 'กระชับ เน้นข้อมูลสำคัญ',
                    selected: _pageSize == PdfPageSize.a5,
                    onTap: () => setState(() => _pageSize = PdfPageSize.a5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ---- Generate button ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_generating ? 'กำลังสร้างเอกสาร...' : 'สร้างเอกสาร PDF'),
                onPressed: _generating || selectedCount == 0 ? null : _generate,
              ),
            ),
            if (selectedCount == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'กรุณาเลือกผู้สมัครก่อนสร้างเอกสาร',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSelectDialog(BuildContext context) async {
    // Navigate to selection mode on search screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ค้นหาและเลือกผู้สมัครจากหน้าค้นหา แล้วกลับมาสร้าง PDF'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _generate() async {
    if (_candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลผู้สมัครที่เลือก')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final pdfBytes = await _buildPdf();
      if (!mounted) return;
      final tmpDir = await getTemporaryDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${tmpDir.path}/รายงานผลการสอบ_$ts.pdf');
      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfSuccessScreen(file: file),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สร้าง PDF ไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final pageFormat =
        _pageSize == PdfPageSize.a4 ? PdfPageFormat.a4 : PdfPageFormat.a5;

    // Load font
    pw.Font? thaiFont;
    pw.Font? thaiFontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Sarabun-Regular.ttf');
      thaiFont = pw.Font.ttf(fontData);
      final fontBoldData = await rootBundle.load('assets/fonts/Sarabun-Bold.ttf');
      thaiFontBold = pw.Font.ttf(fontBoldData);
    } catch (_) {
      // Font not bundled — use Helvetica fallback (Latin only)
      thaiFont = pw.Font.helvetica();
      thaiFontBold = pw.Font.helveticaBold();
    }

    // Load garuda seal image
    pw.ImageProvider? garudaImage;
    try {
      final garudaData = await rootBundle.load('assets/images/garuda.jpg');
      garudaImage = pw.MemoryImage(garudaData.buffer.asUint8List());
    } catch (_) {
      garudaImage = null;
    }

    final baseStyle = pw.TextStyle(font: thaiFont, fontSize: 14);
    final boldStyle = pw.TextStyle(font: thaiFontBold, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(font: thaiFontBold, fontSize: 18, fontWeight: pw.FontWeight.bold);
    final subStyle = pw.TextStyle(font: thaiFont, fontSize: 13);

    // Thai month names
    final thaiMonths = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    final now = DateTime.now();
    final dateStr =
        'วันที่ ${now.day} ${thaiMonths[now.month]} พ.ศ. ${now.year + 543}';

    for (final candidate in _candidates) {
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.fromLTRB(40, 30, 40, 30),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header — garuda + title
                pw.Center(
                  child: pw.Column(
                    children: [
                      // Garuda seal
                      if (garudaImage != null)
                        pw.Image(garudaImage, width: 60, height: 60,
                            fit: pw.BoxFit.contain),
                      if (garudaImage == null)
                        pw.SizedBox(height: 8),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _docTypeTitle(),
                        style: titleStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'สำนักงานคณะกรรมการข้าราชการพลเรือน',
                        style: subStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(dateStr, style: subStyle),
                ),
                pw.SizedBox(height: 12),

                // Photo placeholder
                pw.Center(
                  child: pw.Container(
                    width: 90,
                    height: 110,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'รูปถ่าย',
                        style: pw.TextStyle(
                          font: thaiFont,
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 14),

                // Fields
                _pdfField('ชื่อ-นามสกุล', candidate.fullName, boldStyle, baseStyle),
                _pdfField('เลขประจำตัวสอบ', candidate.examId, boldStyle, baseStyle),
                _pdfField('เลขบัตรประชาชน', candidate.maskedId, boldStyle, baseStyle),
                _pdfField('ตำแหน่ง', candidate.position, boldStyle, baseStyle),
                _pdfField('ภาค/เขต', candidate.region, boldStyle, baseStyle),
                _pdfField('จังหวัด', candidate.province, boldStyle, baseStyle),
                _pdfField('สายงาน', candidate.jobField, boldStyle, baseStyle),
                _pdfField(
                  'คะแนนที่แก้ไข',
                  candidate.score != '-' ? '+${candidate.score}' : '-',
                  boldStyle,
                  baseStyle,
                ),
                _pdfField('สถานะ', candidate.status, boldStyle, baseStyle),
                _pdfField('หน่วยงาน', candidate.agency, boldStyle, baseStyle),

                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'หมายเหตุ: ข้อมูลนี้จัดทำเพื่อการตรวจสอบเท่านั้น',
                    style: pw.TextStyle(
                      font: thaiFont,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  pw.Widget _pdfField(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label, style: labelStyle),
          ),
          pw.Text(' : ', style: valueStyle),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty || value == 'null' ? '-' : value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _docTypeTitle() {
    switch (_docType) {
      case PdfDocType.examReport:
        return 'ใบรายงานผลการสอบ';
      case PdfDocType.applicationLetter:
        return 'หนังสือรับรองการสมัคร';
      case PdfDocType.infoSummary:
        return 'เอกสารรวมข้อมูลผู้สมัคร';
    }
  }
}

// ---- PDF Success screen ----
class _PdfSuccessScreen extends StatelessWidget {
  final File file;
  const _PdfSuccessScreen({required this.file});

  String get _fileName => file.path.split('/').last;
  String get _fileSize {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างเอกสาร PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'สร้างเอกสาร PDF เรียบร้อยแล้ว',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'ไฟล์เอกสารพร้อมใช้งาน\nสามารถดาวน์โหลดหรือแชร์ได้ตามต้องการ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            // File card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: Color(0xFFD32F2F), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'PDF Document · $_fileSize',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('ดาวน์โหลด / เปิดดู'),
                onPressed: _preview,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('แชร์เอกสาร'),
                onPressed: _share,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.popUntil(
                context,
                (route) => route.isFirst,
              ),
              child: const Text('กลับหน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preview() async {
    await Printing.layoutPdf(onLayout: (_) async => file.readAsBytes());
  }

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'รายงานผลการสอบ',
    );
  }
}

// ---- Helper widgets ----
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RadioCard<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<T?> onChanged;

  const _RadioCard({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _SizeCard({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppTheme.primaryColor : AppTheme.textHint,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                sub,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
