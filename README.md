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

Repository hiện tại chưa có ảnh chụp màn hình được commit sẵn.  
Sau khi chụp màn hình app, hãy tạo thư mục `docs/screenshots/` và thêm ảnh vào theo gợi ý bên dưới.

| Splash | Login | Register |
|---|---|---|
| <img src="docs/screenshots/splash.png" width="220" alt="Splash Screen" /> | <img src="docs/screenshots/login.png" width="220" alt="Login Screen" /> | <img src="docs/screenshots/register.png" width="220" alt="Register Screen" /> |

| Home | Chat | Friends |
|---|---|---|
| <img src="docs/screenshots/home.png" width="220" alt="Home Screen" /> | <img src="docs/screenshots/chat.png" width="220" alt="Chat Screen" /> | <img src="docs/screenshots/friends.png" width="220" alt="Friends Screen" /> |

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
| Freezed / Build Runner | Hỗ trợ generate code |
| Equatable | So sánh object |
| UUID | Tạo định danh |
