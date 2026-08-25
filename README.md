# There You Are

> แอปพลิเคชันบันทึกและแชร์พิกัดสถานที่ (Check-in) ที่พัฒนาด้วย Flutter

## ฟีเจอร์หลัก

- **Check-in สถานที่** — บันทึกพิกัด GPS (Latitude & Longitude) พร้อมชื่อสถานที่ รายละเอียด และรูปภาพ
- **แผนที่แบบ Real-time** — ดูตำแหน่ง Check-in ทั้งหมดบนแผนที่ OpenStreetMap
- **เปิดใน Google Maps** — นำทางไปยังตำแหน่ง Check-in ได้ทันที
- **ระบบยืนยันตัวตน OTP** — ลงทะเบียนและยืนยันตัวตนผ่านอีเมลด้วยรหัส OTP 6 หลัก
- **จัดการโปรไฟล์** — แก้ไขชื่อ เปลี่ยนรหัสผ่าน และจัดการบัญชีผู้ใช้
- **Feed สาธารณะ** — ดูรายการ Check-in จากผู้ใช้ทุกคนแบบ Real-time

##  Requirement

- Flutter SDK `^3.12.1`
- Android Studio หรือ VS Code (พร้อม Flutter extension)
- อุปกรณ์ Android / iOS / Web

## วิธีติดตั้ง

### 1. Clone โปรเจกต์

```bash
git clone https://github.com/your-username/there-you-are.git
cd there-you-are
```

### 2. ติดตั้ง Dependencies

```bash
flutter pub get
```

### 3. รันแอป

**Android:**
```bash
flutter run
```

**Web:**
```bash
flutter run -d chrome
```

**Windows:**
```bash
flutter run -d windows
```

## วิธีใช้งาน

### สมัครสมาชิก

1. กดปุ่ม **"สมัครสมาชิกใหม่ (Register)"** บนหน้า Welcome
2. กรอกชื่อ อีเมล และรหัสผ่าน
3. ตรวจสอบรหัส OTP 6 หลักในอีเมล
4. กรอกรหัส OTP เพื่อยืนยันตัวตน

### เข้าสู่ระบบ

1. กดปุ่ม **"เข้าสู่ระบบ (Login)"**
2. กรอกอีเมลและรหัสผ่าน
3. หากลืมรหัสผ่าน กด **"ลืมรหัสผ่าน?"** เพื่อรีเซ็ตผ่าน OTP

### สร้าง Check-in

1. กดปุ่ม **+** (Floating Action Button) ที่มุมขวาล่าง
2. กรอกชื่อสถานที่
3. กด **"ดึงพิกัดสด"** เพื่อดึงตำแหน่ง GPS ปัจจุบัน หรือป้อน Latitude/Longitude ด้วยตนเอง
4. (ตัวเลือก) กด **"เลือกและปักหมุดตำแหน่งบนแผนที่"** เพื่อเลือกตำแหน่งจากแผนที่
5. กรอกรายละเอียดเพิ่มเติม (ไม่บังคับ)
6. เลือกรูปภาพ (ไม่บังคับ)
7. กด **"บันทึก"**

### ดู Feed และแผนที่

- **Feed** — หน้าแรกแสดงรายการ Check-in จากผู้ใช้ทุกคน
- **แผนที่รวม** — กดไอคอนแผนที่เพื่อดูตำแหน่ง Check-in ทั้งหมดบนแผนที่เดียว
- **เปิดใน Google Maps** — กดที่รายการ Check-in แล้วเลือก **"เปิดใน Google Maps"** เพื่อนำทาง

### จัดการบัญชี

- กดไอคอนโปรไฟล์เพื่อดูข้อมูลบัญชี
- แก้ไขชื่อโปรไฟล์ได้ในหน้า Profile
- เปลี่ยนรหัสผ่านได้ในหน้า Settings
- ออกจากระบบ: กดปุ่ม **"ออกจากระบบ"** ในหน้า Profile

## สิทธิ์ที่ต้องการ

| สิทธิ์ | วัตถุประสงค์ |
|--------|-------------|
| Location | ดึงพิกัด GPS สำหรับ Check-in |
| Camera | ถ่ายรูปแนบกับ Check-in |

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Maps:** flutter_map + OpenStreetMap
- **Backend API:** [where-am-i-silk.vercel.app](https://where-am-i-silk.vercel.app)
- **Storage:** flutter_secure_storage

## โครงสร้างโปรเจกต์

```
lib/
├── main.dart                    # Entry point + AuthGate
├── my_home_page.dart            # PDPA page
├── screens/
│   ├── welcome_screen.dart      # หน้า Welcome
│   ├── login_screen.dart        # หน้า Login
│   ├── register_screen.dart     # หน้า Register
│   ├── forgot_password_screen.dart  # หน้าลืมรหัสผ่าน
│   └── home_screen.dart         # หน้าหลัก (Feed + Map)
└── services/
    ├── api_service.dart         # API calls + Auth
    ├── device_service.dart      # ข้อมูลอุปกรณ์
    └── permission_service.dart  # จัดการสิทธิ์
```

---

**There You Are v1.0.0** — บันทึกทุกความทรงจำในทุกการเดินทาง
