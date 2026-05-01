import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import 'storage_remote_datasource.dart';

class CloudinaryStorageDatasource implements StorageRemoteDatasource {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'flutter_unsigned_preset';

  @override
  Future<String> uploadImage(XFile imageFile) async {
    if (_cloudName.isEmpty) {
      throw const StorageException(
        message:
            'Cloudinary Cloud Name không được tìm thấy. Hãy kiểm tra file .env',
      );
    }

    try {
      final uri = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

      // 1. Đọc file dưới dạng bytes
      final bytes = await imageFile.readAsBytes();

      // 2. Tạo FormData cho Dio
      final formData = FormData.fromMap({
        'upload_preset': _uploadPreset,
        'file': MultipartFile.fromBytes(bytes, filename: imageFile.name),
      });

      // 3. Gửi request bằng Dio
      final response = await Dio().post(
        uri,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // 4. Kiểm tra response
      if (response.statusCode != 200 || response.data == null) {
        Logger.error(
          'Cloudinary upload failed: ${response.data}',
          tag: 'Cloudinary',
        );
        throw const StorageException(
          message: 'Failed to upload image to Cloudinary',
        );
      }

      // 5. Parse JSON lấy URL
      final String secureUrl = response.data['secure_url'];

      if (secureUrl.isEmpty) {
        throw const StorageException(message: 'Cloudinary returned empty URL');
      }

      Logger.info('Image uploaded successfully: $secureUrl', tag: 'Cloudinary');
      return secureUrl;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(message: 'Error uploading image: $e');
    }
  }
}
