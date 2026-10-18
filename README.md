# ระบบค้นหาข้อมูลผู้สมัครสอบ
Flutter 3.16+ Android App

## ขั้นตอนการ Build APK

### วิธีที่ 1 — FlutLab.io (แนะนำ ง่ายสุด)
1. ไปที่ https://flutlab.io/workspace
2. สร้าง project ใหม่ (New Project → Import ZIP)
3. อัปโหลดไฟล์ score_lookup.zip นี้
4. **เพิ่มฟอนต์ภาษาไทย** (สำคัญสำหรับ PDF):
   - ดาวน์โหลด Sarabun font: https://fonts.google.com/specimen/Sarabun
   - อัปโหลด `Sarabun-Regular.ttf`, `Sarabun-Bold.ttf`, `Sarabun-SemiBold.ttf` เข้าโฟลเดอร์ `assets/fonts/`
5. กด **Build APK** → ดาวน์โหลด APK

### วิธีที่ 2 — Flutter CLI (Local)
```bash
# ต้องมี Flutter 3.16+ ลงแล้ว
cd score_lookup
flutter pub get
flutter build apk --release
# ไฟล์ APK อยู่ที่: build/app/outputs/flutter-apk/app-release.apk
```

---

## โครงสร้างโปรเจกต์
```
lib/
  main.dart              # Entry point + bottom navigation
  theme/
    app_theme.dart       # สีและสไตล์ทั้งหมด (navy blue #1F3A5F)
  models/
    candidate.dart       # Data model
  database/
    db_helper.dart       # SQLite helper (copy DB from assets on first run)
  providers/
    search_provider.dart # Riverpod state management
  screens/
    home_screen.dart     # หน้าแรก (logo + menu)
    search_screen.dart   # ค้นหา + filter dropdowns
    detail_screen.dart   # รายละเอียดผู้สมัคร
    pdf_create_screen.dart  # สร้าง PDF + share
    settings_screen.dart # ตั้งค่า
  widgets/
    candidate_card.dart  # Card component สำหรับผลค้นหา
assets/
  data.db               # ฐานข้อมูล SQLite (3,966 รายการ)
  fonts/                # วางไฟล์ Sarabun TTF ที่นี่
```

## ฟีเจอร์
- ✅ ค้นหาด้วย ชื่อ / นามสกุล / เลขประจำตัวสอบ / เลขบัตรประชาชน
- ✅ กรองตาม ภาค/เขต, จังหวัด, สถานะ
- ✅ ดูรายละเอียดแต่ละคน
- ✅ สร้าง PDF (3 รูปแบบ: ใบรายงาน / หนังสือรับรอง / รวมข้อมูล)
- ✅ ขนาด A4 หรือ A5
- ✅ ดาวน์โหลด + แชร์ PDF
- ✅ UX/UI สไตล์ราชการ (navy blue #1F3A5F)
- ✅ ไม่มีระบบ login
- ✅ รองรับ Android API 21+ (Android 5.0+)

## Dependencies หลัก
- sqflite ^2.3.0 — SQLite
- pdf ^3.10.7 — สร้าง PDF
- printing ^5.12.0 — เปิด/ดาวน์โหลด PDF
- share_plus ^7.2.1 — แชร์ไฟล์
- flutter_riverpod ^2.4.9 — State management
