import 'package:firebase_database/firebase_database.dart';
import '../../../../core/errors/exceptions.dart';

abstract class PresenceRemoteDatasource {
  Future<void> updatePresenceStatus(String uid, String status);
}

class PresenceRemoteDatasourceImpl implements PresenceRemoteDatasource {
  final FirebaseDatabase database;

  PresenceRemoteDatasourceImpl({required this.database});

  @override
  Future<void> updatePresenceStatus(String uid, String status) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await database.ref('presence/$uid').update({
        'status': status,
        'lastSeen': now,
      });
    } catch (e) {
      throw ServerException(message: 'Failed to update presence status: $e');
    }
  }
}
