# Hệ thống Reports & Data Visualization - Tài liệu kỹ thuật

## Tổng quan

Hệ thống Reports & Data Visualization được thiết kế để cung cấp khả năng tạo báo cáo và hiển thị dữ liệu thống kê một cách trực quan cho ứng dụng quản lý điểm danh. Hệ thống bao gồm các tính năng chính:

- **Dashboard tổng quan**: Hiển thị thống kê tổng quan với các biểu đồ
- **Báo cáo chi tiết**: Tạo báo cáo cho từng module cụ thể
- **Data Visualization**: Biểu đồ tròn, cột, đường để hiển thị dữ liệu
- **CSV Export**: Xuất dữ liệu ra file CSV để phân tích
- **Filtering**: Lọc dữ liệu theo khoảng thời gian

## Kiến trúc hệ thống

### 1. ReportsService (`reports_service.dart`)
- **Chức năng chính**: Xử lý logic tạo báo cáo và thống kê
- **API Integration**: Kết nối với backend API để lấy dữ liệu
- **Data Processing**: Xử lý và tổng hợp dữ liệu
- **CSV Export**: Xuất dữ liệu ra file CSV

### 2. ReportsStateNotifier (`reports_provider.dart`)
- **State Management**: Quản lý trạng thái reports
- **Filter Management**: Quản lý bộ lọc thời gian
- **Export State**: Theo dõi trạng thái xuất file
- **Error Handling**: Xử lý lỗi và hiển thị thông báo

### 3. Chart Components (`chart_widgets.dart`)
- **ActivityOverTimeChart**: Biểu đồ đường cho hoạt động theo thời gian
- **AttendancePieChart**: Biểu đồ tròn cho thống kê điểm danh
- **UserRoleBarChart**: Biểu đồ cột cho phân bố người dùng
- **StatsCard**: Card hiển thị thống kê tổng quan

### 4. AdminReportsScreen (`admin_reports_screen.dart`)
- **Tab Navigation**: 4 tab chính (Tổng quan, Hoạt động, Người dùng, Điểm danh)
- **Filter Interface**: Giao diện lọc theo thời gian
- **Export Interface**: Giao diện xuất báo cáo
- **Responsive Design**: Thiết kế responsive cho mobile

## Dependencies đã thêm

```yaml
fl_chart: ^0.68.0      # Charts library
csv: ^6.0.0           # CSV export
intl: ^0.19.0         # Date formatting
```

## Tính năng chi tiết

### 1. Dashboard Tổng quan
- **Stats Cards**: Hiển thị các số liệu tổng quan
- **Attendance Pie Chart**: Biểu đồ tròn điểm danh
- **User Role Bar Chart**: Biểu đồ cột phân bố vai trò
- **Date Range Filter**: Lọc theo khoảng thời gian

### 2. Tab Hoạt động
- **Activity Over Time Chart**: Biểu đồ đường theo tháng
- **Generate Report**: Tạo báo cáo chi tiết hoạt động
- **Export CSV**: Xuất dữ liệu hoạt động

### 3. Tab Người dùng
- **User Role Distribution**: Phân bố người dùng theo vai trò
- **User Report**: Báo cáo chi tiết người dùng
- **Export Users**: Xuất danh sách người dùng

### 4. Tab Điểm danh
- **Attendance Statistics**: Thống kê điểm danh
- **Attendance Report**: Báo cáo chi tiết điểm danh
- **Export Attendances**: Xuất dữ liệu điểm danh

## Cấu trúc dữ liệu

### Dashboard Stats
```json
{
  "totalActivities": 10,
  "activeActivities": 3,
  "upcomingActivities": 2,
  "completedActivities": 5,
  "totalUsers": 50,
  "adminUsers": 2,
  "managerUsers": 8,
  "studentUsers": 40,
  "totalRegistrations": 200,
  "totalAttendances": 150,
  "presentAttendances": 120,
  "absentAttendances": 20,
  "lateAttendances": 10
}
```

### Activities Over Time
```json
[
  {"month": "2024-01", "count": 5},
  {"month": "2024-02", "count": 8},
  {"month": "2024-03", "count": 12}
]
```

### Attendance Stats
```json
[
  {"status": "present", "count": 120, "label": "Có mặt"},
  {"status": "absent", "count": 20, "label": "Vắng mặt"},
  {"status": "late", "count": 10, "label": "Đi muộn"}
]
```

### User Role Stats
```json
[
  {"role": "admin", "count": 2, "label": "Quản trị viên"},
  {"role": "manager", "count": 8, "label": "Người quản lý"},
  {"role": "student", "count": 40, "label": "Sinh viên"}
]
```

## CSV Export Format

### Activities CSV
```csv
ID,Tiêu đề,Mô tả,Thời gian bắt đầu,Thời gian kết thúc,Trạng thái,Địa điểm
1,Hội thảo công nghệ,Mô tả hội thảo,2024-01-01T09:00:00Z,2024-01-01T17:00:00Z,completed,Hội trường A
```

### Users CSV
```csv
ID,Tên,Email,Vai trò,Ngày tạo
1,Nguyễn Văn A,admin@example.com,admin,2024-01-01T00:00:00Z
```

### Attendances CSV
```csv
ID,User ID,Activity ID,Trạng thái,Thời gian điểm danh
1,1,1,present,2024-01-01T09:00:00Z
```

### Registrations CSV
```csv
ID,User ID,Activity ID,Thời gian đăng ký
1,1,1,2024-01-01T08:00:00Z
```

## Giao diện người dùng

### AdminReportsScreen
- **AppBar**: Tiêu đề + nút filter + nút export
- **TabBar**: 4 tab chính với icons
- **TabBarView**: Nội dung từng tab
- **Loading Overlay**: Hiển thị khi đang xử lý

### Filter Dialog
- **Date Range Picker**: Chọn từ ngày và đến ngày
- **Clear Filter**: Xóa bộ lọc
- **Apply Filter**: Áp dụng bộ lọc

### Export Dialog
- **Report Types**: Chọn loại báo cáo
- **Export Options**: Xuất CSV
- **Progress Indicator**: Hiển thị tiến trình

## Charts và Data Visualization

### 1. Line Chart (Activities Over Time)
- **Library**: fl_chart
- **Type**: LineChart
- **Features**: Curved lines, dots, area fill
- **Data**: Monthly activity counts

### 2. Pie Chart (Attendance Stats)
- **Library**: fl_chart
- **Type**: PieChart
- **Features**: Color-coded sections, labels
- **Data**: Present/Absent/Late counts

### 3. Bar Chart (User Roles)
- **Library**: fl_chart
- **Type**: BarChart
- **Features**: Color-coded bars, labels
- **Data**: Role distribution

### 4. Stats Cards
- **Design**: Material Design cards
- **Features**: Icons, colors, tap actions
- **Data**: Key metrics display

## Xử lý lỗi

### Error Types
1. **API Errors**: Lỗi kết nối hoặc dữ liệu
2. **File Export Errors**: Lỗi ghi file CSV
3. **Data Processing Errors**: Lỗi xử lý dữ liệu
4. **Chart Rendering Errors**: Lỗi hiển thị biểu đồ

### Error Handling Strategy
- **Try-Catch**: Bọc tất cả operations
- **AsyncValue**: Sử dụng Riverpod AsyncValue
- **User Feedback**: SnackBar thông báo lỗi
- **Fallback UI**: Hiển thị UI thay thế khi lỗi

## Performance

### Optimization
- **Lazy Loading**: Load dữ liệu khi cần
- **Caching**: Cache dữ liệu với Riverpod
- **Async Operations**: Không block UI thread
- **Memory Management**: Giải phóng bộ nhớ

### Monitoring
- **Loading States**: Hiển thị trạng thái loading
- **Error States**: Hiển thị trạng thái lỗi
- **Success States**: Hiển thị trạng thái thành công
- **Progress Tracking**: Theo dõi tiến trình export

## Bảo mật

### Data Protection
- **Role-based Access**: Chỉ admin truy cập được
- **Data Validation**: Kiểm tra dữ liệu trước khi hiển thị
- **File Permissions**: Kiểm tra quyền ghi file

### Access Control
- **Authentication**: Kiểm tra token trước khi truy cập
- **Authorization**: Kiểm tra quyền admin
- **Session Management**: Quản lý phiên đăng nhập

## Testing

### Test Cases
1. **Chart Rendering**: Biểu đồ hiển thị đúng
2. **Data Processing**: Xử lý dữ liệu chính xác
3. **CSV Export**: Xuất file CSV thành công
4. **Filtering**: Lọc dữ liệu đúng
5. **Error Handling**: Xử lý lỗi đúng cách

### Test Data
- **Small Dataset**: < 100 records
- **Medium Dataset**: 100-1000 records
- **Large Dataset**: > 1000 records
- **Empty Data**: Dữ liệu rỗng
- **Invalid Data**: Dữ liệu không hợp lệ

## Mở rộng trong tương lai

### Planned Features
1. **More Chart Types**: Scatter plots, heatmaps
2. **Real-time Updates**: Cập nhật real-time
3. **Advanced Filtering**: Lọc theo nhiều tiêu chí
4. **PDF Export**: Xuất báo cáo PDF
5. **Scheduled Reports**: Báo cáo tự động
6. **Custom Dashboards**: Dashboard tùy chỉnh

### Technical Improvements
1. **Chart Animations**: Hiệu ứng animation
2. **Interactive Charts**: Biểu đồ tương tác
3. **Data Drill-down**: Xem chi tiết dữ liệu
4. **Export Formats**: Nhiều định dạng xuất
5. **Performance Optimization**: Tối ưu hiệu suất

## Troubleshooting

### Common Issues
1. **Charts Not Loading**: Kiểm tra dữ liệu API
2. **CSV Export Failed**: Kiểm tra quyền ghi file
3. **Filter Not Working**: Kiểm tra logic filter
4. **Performance Issues**: Kiểm tra kích thước dữ liệu

### Debug Information
- **Console Logs**: Chi tiết trong console
- **Error Messages**: Thông báo lỗi rõ ràng
- **Network Requests**: Theo dõi API calls
- **State Changes**: Theo dõi state changes

## Kết luận

Hệ thống Reports & Data Visualization đã được thiết kế và triển khai đầy đủ với các tính năng cốt lõi:

✅ **UI hoàn chỉnh** với tab navigation và responsive design
✅ **Charts hiển thị đúng** với fl_chart library
✅ **CSV export hoạt động** với đầy đủ định dạng
✅ **Filtering functionality** với date range picker
✅ **Data visualization** với multiple chart types
✅ **Error handling** toàn diện với user feedback

Hệ thống sẵn sàng cho production và có thể mở rộng thêm các tính năng nâng cao trong tương lai như real-time updates, advanced filtering, và custom dashboards.
