import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';

abstract class StorageRemoteDatasource {
  /// Upload file ảnh lên Cloudinary và trả về URL công khai.
  /// Dùng XFile thay vì File để hỗ trợ cả Flutter Web.
  Future<String> uploadImage(XFile imageFile);
}
