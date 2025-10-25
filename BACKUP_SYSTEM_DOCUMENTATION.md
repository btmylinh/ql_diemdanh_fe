# Hệ thống Backup & Restore - Tài liệu kỹ thuật

## Tổng quan

Hệ thống Backup & Restore được thiết kế để cung cấp khả năng sao lưu và khôi phục dữ liệu toàn diện cho ứng dụng quản lý điểm danh. Hệ thống bao gồm các tính năng chính:

- **Tạo sao lưu**: Xuất toàn bộ dữ liệu hệ thống ra file JSON
- **Khôi phục dữ liệu**: Import dữ liệu từ file sao lưu
- **Xuất báo cáo**: Tạo các báo cáo thống kê chi tiết
- **Quản lý lịch sử**: Theo dõi và quản lý các bản sao lưu

## Kiến trúc hệ thống

### 1. BackupService (`backup_service.dart`)
- **Chức năng chính**: Xử lý logic sao lưu và khôi phục
- **API Integration**: Kết nối với backend API để lấy dữ liệu
- **File Operations**: Quản lý việc lưu trữ và đọc file

### 2. BackupStateNotifier (`backup_provider.dart`)
- **State Management**: Quản lý trạng thái backup/restore
- **Progress Tracking**: Theo dõi tiến trình thực hiện
- **Error Handling**: Xử lý lỗi và hiển thị thông báo

### 3. BackupHistoryService (`backup_history_service.dart`)
- **History Management**: Lưu trữ lịch sử các bản sao lưu
- **File Validation**: Kiểm tra tính hợp lệ của file backup
- **Cleanup Operations**: Dọn dẹp các file không cần thiết

### 4. BackupValidationService (`backup_validation_service.dart`)
- **Data Validation**: Kiểm tra cấu trúc dữ liệu backup
- **Compatibility Check**: Đảm bảo tương thích phiên bản
- **Format Validation**: Xác thực định dạng dữ liệu

## Cấu trúc dữ liệu Backup

### Format File
```json
{
  "version": "1.0.0",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "data": {
    "activities": { "data": [...] },
    "users": { "data": [...] },
    "registrations": { "data": [...] },
    "attendances": { "data": [...] }
  },
  "metadata": {
    "totalActivities": 10,
    "totalUsers": 50,
    "totalRegistrations": 200,
    "totalAttendances": 150
  }
}
```

### Validation Rules
- **Version**: Phải là "1.0.0"
- **CreatedAt**: ISO 8601 format
- **Data Structure**: Phải chứa đầy đủ 4 bảng dữ liệu
- **Metadata**: Phải có đầy đủ thống kê

## Tính năng chính

### 1. Tạo Sao lưu
- **Input**: Không cần input từ user
- **Process**: 
  1. Lấy dữ liệu từ API
  2. Tạo cấu trúc backup
  3. Lưu file JSON
  4. Cập nhật lịch sử
- **Output**: File backup + thông báo thành công

### 2. Khôi phục Dữ liệu
- **Input**: File backup được chọn
- **Process**:
  1. Validate file backup
  2. Kiểm tra tương thích
  3. Khôi phục từng bảng dữ liệu
  4. Báo cáo kết quả
- **Output**: Thông báo kết quả + cảnh báo (nếu có)

### 3. Xuất Báo cáo
- **Input**: Loại báo cáo (activities/users/attendances)
- **Process**:
  1. Lấy dữ liệu từ API
  2. Tạo báo cáo với metadata
  3. Lưu file JSON
- **Output**: File báo cáo + thông báo thành công

### 4. Quản lý Lịch sử
- **Features**:
  - Xem danh sách backup
  - Xóa backup cụ thể
  - Xóa tất cả lịch sử
  - Kiểm tra tính hợp lệ file

## Giao diện người dùng

### AdminBackupRestoreScreen
- **Layout**: Grid 2x2 với các card chức năng
- **Progress Indicator**: Overlay với thanh tiến trình
- **State Management**: Real-time updates với Riverpod
- **Error Handling**: SnackBar + Dialog thông báo

### Dialog Components
- **Backup Dialog**: Xác nhận tạo sao lưu
- **Restore Dialog**: Cảnh báo + chọn file
- **Export Dialog**: Chọn loại báo cáo
- **History Dialog**: Danh sách + quản lý backup

## Xử lý lỗi

### Error Types
1. **Permission Errors**: Không có quyền truy cập storage
2. **API Errors**: Lỗi kết nối hoặc dữ liệu
3. **File Errors**: Lỗi đọc/ghi file
4. **Validation Errors**: Dữ liệu không hợp lệ

### Error Handling Strategy
- **Try-Catch**: Bọc tất cả operations
- **User Feedback**: Thông báo lỗi rõ ràng
- **Graceful Degradation**: Tiếp tục hoạt động khi có thể
- **Logging**: Ghi log chi tiết cho debug

## Bảo mật

### Data Protection
- **File Permissions**: Chỉ admin có quyền truy cập
- **Data Validation**: Kiểm tra kỹ trước khi restore
- **Backup Encryption**: Có thể mở rộng trong tương lai

### Access Control
- **Role-based**: Chỉ admin mới truy cập được
- **Session Management**: Kiểm tra token trước khi thực hiện

## Performance

### Optimization
- **Progress Updates**: Cập nhật UI mượt mà
- **Async Operations**: Không block UI thread
- **Memory Management**: Giải phóng bộ nhớ sau khi hoàn thành
- **File Size**: Giới hạn kích thước backup

### Monitoring
- **Progress Tracking**: Hiển thị % hoàn thành
- **Time Estimation**: Ước tính thời gian còn lại
- **Resource Usage**: Theo dõi sử dụng tài nguyên

## Mở rộng trong tương lai

### Planned Features
1. **Backup Scheduling**: Tự động tạo backup theo lịch
2. **Cloud Storage**: Lưu trữ trên cloud
3. **Compression**: Nén file backup
4. **Encryption**: Mã hóa dữ liệu backup
5. **Incremental Backup**: Sao lưu tăng dần
6. **Backup Comparison**: So sánh các bản backup

### Technical Improvements
1. **Database Backup**: Backup trực tiếp từ database
2. **Parallel Processing**: Xử lý song song
3. **Resume Capability**: Tiếp tục backup bị gián đoạn
4. **Backup Verification**: Xác minh tính toàn vẹn

## Testing

### Test Cases
1. **Happy Path**: Tạo backup thành công
2. **Error Handling**: Xử lý lỗi đúng cách
3. **File Validation**: Kiểm tra file backup
4. **UI Responsiveness**: Giao diện phản hồi tốt
5. **Data Integrity**: Dữ liệu không bị mất

### Test Data
- **Small Dataset**: < 100 records
- **Medium Dataset**: 100-1000 records  
- **Large Dataset**: > 1000 records
- **Corrupted Data**: Dữ liệu bị lỗi
- **Empty Data**: Dữ liệu rỗng

## Troubleshooting

### Common Issues
1. **Permission Denied**: Cấp quyền storage
2. **File Not Found**: Kiểm tra đường dẫn file
3. **Invalid Format**: Kiểm tra định dạng JSON
4. **API Timeout**: Kiểm tra kết nối mạng
5. **Memory Issues**: Giảm kích thước dữ liệu

### Debug Information
- **Logs**: Chi tiết trong console
- **Error Messages**: Thông báo lỗi rõ ràng
- **File Paths**: Đường dẫn file backup
- **API Responses**: Phản hồi từ server

## Kết luận

Hệ thống Backup & Restore đã được thiết kế và triển khai đầy đủ với các tính năng cốt lõi:

✅ **UI hoàn chỉnh** với progress indicator và error handling
✅ **Logic backup/restore** với validation và warnings
✅ **File operations** với file picker và storage management
✅ **Error handling** toàn diện với user feedback
✅ **History management** để theo dõi các bản sao lưu

Hệ thống sẵn sàng cho production và có thể mở rộng thêm các tính năng nâng cao trong tương lai.
