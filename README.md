<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.11.4+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-SDK%20%5E3.11.4-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-5B67CA?style=for-the-badge)
![GoRouter](https://img.shields.io/badge/GoRouter-Routing-222222?style=for-the-badge)

</div>

## Giới thiệu

**StarRail App** là một ứng dụng chat được xây dựng bằng **Flutter** và **Firebase**.  
Là một ứng dụng chat có phong cách tương tự Discord: người dùng có thể đăng nhập, tạo hồ sơ, tham gia hoặc tạo server, quản lý channel, nhắn tin và sử dụng chức năng bạn bè/DM.

Project được tổ chức theo hướng **clean architecture**, để dễ mở rộng, bảo trì và phát triển.

## Demo

### Hình ảnh giao diện
| Splash | Login | Register |
|---|---|---|
| <img width="442" height="834" alt="image" src="https://github.com/user-attachments/assets/0d73ffc0-14b4-48f3-93d5-2606acce5c8c" /> | <img width="422" height="826" alt="image" src="https://github.com/user-attachments/assets/bd6a77a2-6277-4c3a-8022-ae145f44e222" /> | <img width="422" height="840" alt="image" src="https://github.com/user-attachments/assets/9189d21d-b30f-4423-9a51-7d97b821e28d" /> |

| Home | Chat | Friends |
|---|---|---|
| <img width="455" height="834" alt="image" src="https://github.com/user-attachments/assets/a5b1f227-0533-42be-9198-495358fc7946" /> | <img width="426" height="826" alt="image" src="https://github.com/user-attachments/assets/e14ed606-28cc-4ef1-87c8-e6d9dc12afd4" /> | <img width="451" height="836" alt="image" src="https://github.com/user-attachments/assets/61dc3a62-240a-4ce3-8d30-952708fddc3e" /> |

## Tính năng chính

### Xác thực và hồ sơ người dùng

- Màn hình Splash.
- Đăng nhập tài khoản.
- Đăng ký tài khoản.
- Tạo hồ sơ người dùng sau khi xác thực.
- Quản lý trạng thái đăng nhập bằng Firebase Authentication và Riverpod.
- Cập nhật trạng thái hiện diện của người dùng theo lifecycle của ứng dụng.

### Server và channel

- Tạo server mới.
- Tham gia server.
- Quản lý thiết lập server.
- Quản lý channel.
- Quản lý role trong server.
- Tự reset server/channel đang chọn khi người dùng đổi tài khoản hoặc không còn quyền truy cập server.

### Tin nhắn và bạn bè

- Màn hình chat.
- Danh sách bạn bè.
- Thêm bạn bè.
- Danh sách DM.
- Màn hình nhắn tin trực tiếp.

### Admin

- Màn hình Admin Console.

## Công nghệ sử dụng

| Công nghệ / Package | Vai trò |
|---|---|
| Flutter | Xây dựng giao diện đa nền tảng |
| Dart | Ngôn ngữ lập trình chính |
| Firebase Core | Khởi tạo Firebase |
| Firebase Auth | Xác thực người dùng |
| Cloud Firestore | Lưu trữ dữ liệu dạng document |
| Firebase Realtime Database | Dữ liệu realtime |
| Flutter Riverpod | Quản lý state |
| GoRouter | Điều hướng màn hình |
| Dio | Gọi API, trong repo được ghi chú dùng cho Cloudinary API upload ảnh |
| Image Picker | Chọn ảnh từ thiết bị |
| Image Cropper | Cắt/chỉnh ảnh |
| Flutter Dotenv | Đọc biến môi trường từ file `.env` |
| Intl | Định dạng ngày tháng, có khởi tạo locale `vi_VN` |
| Equatable | So sánh object |
| UUID | Tạo định danh |
