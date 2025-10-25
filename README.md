# Quản Lý Điểm Danh - Flutter Mobile App

## 📱 Mô tả dự án

Ứng dụng mobile Flutter cho hệ thống quản lý điểm danh sinh viên tham gia các hoạt động tại Khoa CNTT. Ứng dụng hỗ trợ đa nền tảng (Android, iOS, Web) với giao diện thân thiện và trải nghiệm người dùng tốt.

## ✨ Tính năng chính

### 👨‍🎓 Sinh viên (Student)
- **🔐 Đăng ký/Đăng nhập**: Tạo tài khoản và đăng nhập hệ thống
- **📅 Xem hoạt động**: Duyệt danh sách hoạt động có sẵn
- **🔍 Tìm kiếm**: Tìm kiếm và lọc hoạt động theo tiêu chí
- **📝 Đăng ký**: Đăng ký tham gia hoạt động quan tâm
- **📱 Quét QR**: Quét mã QR để điểm danh
- **📊 Theo dõi**: Xem lịch sử điểm danh và hoạt động đã tham gia
- **👤 Hồ sơ**: Cập nhật thông tin cá nhân

### 👨‍💼 Quản lý (Manager)
- **📅 Quản lý hoạt động**: Tạo, sửa, xóa hoạt động
- **👥 Quản lý sinh viên**: Xem danh sách sinh viên đăng ký
- **📱 Điểm danh**: Quản lý phiên điểm danh bằng QR
- **📊 Báo cáo**: Xuất báo cáo danh sách sinh viên tham gia
- **📈 Thống kê**: Xem thống kê hoạt động

### 👨‍💻 Quản trị (Admin)
- **👥 Quản lý người dùng**: Quản lý tài khoản sinh viên và quản lý
- **📅 Quản lý hoạt động**: Quản lý toàn bộ hoạt động trong hệ thống
- **💾 Sao lưu**: Backup và restore dữ liệu hệ thống
- **📊 Báo cáo tổng hợp**: Xem báo cáo và thống kê toàn hệ thống
- **📈 Dashboard**: Tổng quan hệ thống với biểu đồ trực quan

## 🛠️ Công nghệ sử dụng

- **Flutter** - Cross-platform framework
- **Dart** - Programming language
- **Riverpod** - State management
- **Go Router** - Navigation
- **Dio** - HTTP client
- **Flutter Secure Storage** - Secure data storage
- **QR Flutter** - QR code display
- **Mobile Scanner** - QR code scanning
- **FL Chart** - Charts and graphs
- **Google Fonts** - Typography
- **Add 2 Calendar** - Calendar integration
- **File Saver** - File export functionality

## 📦 Cài đặt

### Yêu cầu hệ thống
- Flutter SDK (v3.9.2 trở lên)
- Dart SDK
- Android Studio / VS Code
- Android SDK (cho Android)
- Xcode (cho iOS - macOS only)

### Các bước cài đặt

1. **Clone repository và di chuyển vào thư mục frontend**
   ```bash
   cd ql_diemdanh_fe
   ```

2. **Cài đặt dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu hình API endpoint**
   - Mở file `lib/config.dart`
   - Cập nhật `baseUrl` trỏ đến backend API:
     ```dart
     const String baseUrl = 'http://localhost:4000';
     ```

4. **Chạy ứng dụng**
   ```bash
   # Chạy trên Android
flutter run

   # Chạy trên iOS (macOS only)
   flutter run -d ios
   
   # Chạy trên Web
   flutter run -d web
   
   # Chạy trên desktop
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   ```

## 🚀 Sử dụng

### Đăng nhập hệ thống
1. Mở ứng dụng
2. Chọn "Đăng nhập" nếu đã có tài khoản
3. Nhập email và mật khẩu
4. Hệ thống sẽ tự động chuyển hướng theo vai trò

### Đăng ký tài khoản sinh viên
1. Chọn "Đăng ký"
2. Điền thông tin: Họ tên, Email, Mã số sinh viên, Lớp, Số điện thoại
3. Tạo mật khẩu
4. Xác nhận đăng ký

### Sinh viên - Đăng ký hoạt động
1. Vào "Hoạt động" từ menu chính
2. Duyệt danh sách hoạt động
3. Chọn hoạt động quan tâm
4. Xem chi tiết và nhấn "Đăng ký"

### Sinh viên - Điểm danh
1. Vào "Quét QR" từ menu chính
2. Cho phép truy cập camera
3. Quét mã QR tại hoạt động
4. Xác nhận điểm danh

### Quản lý - Tạo hoạt động
1. Đăng nhập với tài khoản Manager
2. Vào "Hoạt động" → "Tạo mới"
3. Điền thông tin hoạt động
4. Lưu hoạt động

### Quản lý - Điểm danh sinh viên
1. Vào hoạt động đã tạo
2. Chọn "Điểm danh"
3. Hiển thị mã QR cho sinh viên quét
4. Theo dõi danh sách điểm danh

## 📁 Cấu trúc thư mục

```
ql_diemdanh_fe/
├── lib/
│   ├── config.dart              # Cấu hình API
│   ├── main.dart               # Entry point
│   ├── theme.dart              # Theme và styling
│   ├── core/                   # Core utilities
│   └── features/               # Feature modules
│       ├── auth/               # Authentication
│       │   ├── auth_provider.dart
│       │   ├── auth_repository.dart
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   └── user_provider.dart
│       ├── student/            # Student features
│       │   ├── data/           # Data layer
│       │   └── presentation/   # UI screens
│       ├── manager/            # Manager features
│       │   ├── data/           # Data layer
│       │   ├── presentation/   # UI screens
│       │   └── utils/          # Utilities
│       └── admin/              # Admin features
│           ├── data/           # Data layer
│           └── presentation/   # UI screens
├── android/                    # Android specific files
├── ios/                       # iOS specific files
├── web/                       # Web specific files
├── windows/                   # Windows specific files
├── macos/                     # macOS specific files
├── linux/                     # Linux specific files
├── test/                      # Test files
├── pubspec.yaml               # Dependencies
└── README.md
```

## 🎨 UI/UX Features

- **Material Design 3**: Giao diện hiện đại theo chuẩn Material Design
- **Dark/Light Theme**: Hỗ trợ chế độ sáng/tối
- **Responsive Design**: Tương thích nhiều kích thước màn hình
- **Smooth Animations**: Hiệu ứng chuyển động mượt mà
- **Intuitive Navigation**: Điều hướng trực quan và dễ sử dụng
- **Accessibility**: Hỗ trợ người dùng khuyết tật

## 📱 Screenshots

### Sinh viên
- Dashboard sinh viên với hoạt động gần đây
- Danh sách hoạt động với tìm kiếm và lọc
- Chi tiết hoạt động với thông tin đầy đủ
- Màn hình quét QR với camera preview
- Hồ sơ cá nhân với thông tin chi tiết

### Quản lý
- Dashboard quản lý với thống kê tổng quan
- Form tạo/sửa hoạt động với validation
- Danh sách sinh viên đăng ký với export
- Phiên điểm danh với mã QR và danh sách

### Quản trị
- Dashboard admin với biểu đồ thống kê
- Quản lý người dùng với phân quyền
- Quản lý hoạt động toàn hệ thống
- Backup/restore với progress indicator

## 🔧 Build và Deploy

### Build APK cho Android
```bash
flutter build apk --release
```

### Build App Bundle cho Google Play
```bash
flutter build appbundle --release
```

### Build IPA cho iOS
```bash
flutter build ios --release
```

### Build Web
```bash
flutter build web --release
```

### Build Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🧪 Testing

```bash
# Chạy unit tests
flutter test

# Chạy integration tests
flutter test integration_test/

# Chạy tests với coverage
flutter test --coverage
```

## 📊 State Management

Ứng dụng sử dụng **Riverpod** cho state management với kiến trúc Clean Architecture:

- **Provider**: Quản lý state và business logic
- **Repository**: Xử lý data layer và API calls
- **Model**: Định nghĩa data structures
- **Screen**: UI components và user interactions

## 🔒 Bảo mật

- **Secure Storage**: Lưu trữ token và thông tin nhạy cảm
- **JWT Authentication**: Xác thực người dùng với JWT
- **Input Validation**: Validate dữ liệu đầu vào
- **Permission Handling**: Quản lý quyền truy cập camera, storage

## 📝 Ghi chú

- Ứng dụng hỗ trợ offline mode cho một số tính năng
- QR code được tạo tự động khi tạo hoạt động
- Hỗ trợ export danh sách sinh viên ra file CSV
- Tích hợp calendar để thêm sự kiện
- Responsive design cho tablet và desktop

## 🐛 Troubleshooting

### Lỗi thường gặp

1. **Camera không hoạt động**
   - Kiểm tra quyền camera trong settings
   - Restart ứng dụng

2. **Không kết nối được API**
   - Kiểm tra URL trong `config.dart`
   - Đảm bảo backend đang chạy

3. **Build lỗi**
   - Chạy `flutter clean`
   - Chạy `flutter pub get`
   - Kiểm tra Flutter version

## 🤝 Đóng góp

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📄 License

Dự án này được phân phối dưới giấy phép MIT.

## 📞 Liên hệ

Nếu có vấn đề hoặc câu hỏi, vui lòng tạo issue trên GitHub repository.