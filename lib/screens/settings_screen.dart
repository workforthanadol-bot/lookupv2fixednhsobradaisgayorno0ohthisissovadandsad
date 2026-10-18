import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsGroup(
            title: 'ข้อมูลการใช้งาน',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'ข้อมูลเวอร์ชันและนโยบาย',
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                onTap: () => _showAbout(context),
              ),
              _SettingsTile(
                icon: Icons.search_off,
                title: 'ล้างข้อมูลค้นหา',
                subtitle: 'ลบประวัติการค้นหา',
                onTap: () => _confirmClear(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'เกี่ยวกับแอป',
            children: [
              _SettingsTile(
                icon: Icons.apps,
                title: 'เกี่ยวกับแอป',
                subtitle: 'เวอร์ชัน 1.0.0',
                onTap: () => _showAbout(context),
              ),
              _SettingsTile(
                icon: Icons.phone_outlined,
                title: 'ติดต่อหน่วยงาน',
                subtitle: 'สำนักงาน ก.พ.',
                onTap: () => _showContact(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'สำนักงานคณะกรรมการข้าราชการพลเรือน\n© ${DateTime.now().year + 543}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ระบบค้นหาข้อมูลผู้สมัครสอบ',
      applicationVersion: '1.0.0',
      applicationLegalese:
          '© สำนักงานคณะกรรมการข้าราชการพลเรือน\nพัฒนาเพื่อการตรวจสอบข้อมูลภายในเท่านั้น',
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ล้างข้อมูลค้นหา'),
        content: const Text('ต้องการล้างประวัติการค้นหาทั้งหมดหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ล้างข้อมูลค้นหาเรียบร้อย')),
              );
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ติดต่อหน่วยงาน'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สำนักงานคณะกรรมการข้าราชการพลเรือน'),
            SizedBox(height: 8),
            Text('โทร: 02-547-1000'),
            Text('เว็บไซต์: www.ocsc.go.th'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}
