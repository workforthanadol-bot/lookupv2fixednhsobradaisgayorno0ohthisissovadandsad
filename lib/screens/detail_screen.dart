import 'package:flutter/material.dart';
import '../models/candidate.dart';
import '../theme/app_theme.dart';
import 'pdf_create_screen.dart';

class DetailScreen extends StatelessWidget {
  final Candidate candidate;

  const DetailScreen({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('รายละเอียดผู้สมัครสอบ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'สร้าง PDF',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfCreateScreen(candidates: [candidate]),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Profile header card ---
            _buildProfileCard(context),
            const SizedBox(height: 14),
            // --- Details card ---
            _buildDetailsCard(),
            const SizedBox(height: 14),
            // --- Exam info card ---
            _buildExamCard(),
            const SizedBox(height: 24),
            // --- PDF button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('สร้างเอกสาร PDF'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfCreateScreen(candidates: [candidate]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 38,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _statusChip(),
                  const SizedBox(height: 4),
                  Text(
                    'เลขประจำตัวสอบ: ${candidate.examId}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip() {
    Color bg;
    Color fg;
    if (candidate.status.contains('ผ่าน') && !candidate.status.contains('ไม่')) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (candidate.status.contains('ไม่ผ่าน')) {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    } else {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        candidate.status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('ข้อมูลส่วนตัว'),
            const Divider(height: 16),
            _InfoRow(label: 'เลขบัตรประชาชน', value: candidate.maskedId),
            _InfoRow(label: 'ตำแหน่ง', value: candidate.position),
            _InfoRow(label: 'สายงาน', value: candidate.jobField),
            _InfoRow(label: 'หน่วยงาน', value: candidate.agency),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('ข้อมูลการสอบ'),
            const Divider(height: 16),
            _InfoRow(label: 'ภาค/เขต', value: candidate.region),
            _InfoRow(label: 'จังหวัด', value: candidate.province),
            if (candidate.score != '-' && candidate.score.isNotEmpty)
              _ScoreRow(score: candidate.score),
            _InfoRow(label: 'ลำดับที่', value: '${candidate.orderNo}'),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
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
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(color: AppTheme.textHint)),
          Expanded(
            child: Text(
              value.isEmpty || value == 'null' ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String score;
  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'คะแนนที่แก้ไข',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
          const Text(' : ', style: TextStyle(color: AppTheme.textHint)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$score',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B5800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
