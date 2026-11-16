# task_manager

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Các API bổ sung trong bản hoàn thiện
- `GET /api/statistics/tasks`, `/assignments`, `/deadlines`: thống kê công việc.
- `GET /api/notifications`, `/unread-count`, `PATCH /:id/read`, `PATCH /read-all`: thông báo trong ứng dụng.
- `GET|POST /api/tasks/:id/assignees`, `PATCH|DELETE /api/tasks/:id/assignees/:userId`: giao và quản lý người phụ trách.
- `GET /api/tasks/:id/activities`: lịch sử hoạt động.

Các API trên yêu cầu JWT. Email hiện mới ghi nhận ý định gửi vào email log trạng thái `pending`; cần cấu hình SMTP và triển khai worker gửi thư trước khi có thể khẳng định email đã được gửi thật.
