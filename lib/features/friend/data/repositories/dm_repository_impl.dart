// lib/features/friend/data/repositories/dm_repository_impl.dart
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/dm_chat_entity.dart';
import '../../domain/entities/dm_message_entity.dart';
import '../../domain/repositories/dm_repository.dart';
import '../datasources/dm_remote_datasource.dart';

class DmRepositoryImpl implements DmRepository {
  final DmRemoteDatasource _datasource;

  DmRepositoryImpl({required DmRemoteDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<Failure, String>> getOrCreateDmChat(
    String otherUserId,
  ) async {
    try {
      final chatId = await _datasource.getOrCreateDmChat(otherUserId);
      return Either.right(chatId);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DmChatEntity>> createGroupDm({
    required List<String> participantIds,
    required String name,
  }) async {
    try {
      final model = await _datasource.createGroupDm(
        participantIds: participantIds,
        name: name,
      );
      return Either.right(model.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<DmChatEntity>>> watchDmChats(String userId) {
    return _datasource.watchDmChats(userId).map(
      (models) => Either.right<Failure, List<DmChatEntity>>(
        models.map((m) => m.toEntity()).toList(),
      ),
    ).handleError(
      (e) => Either.left<Failure, List<DmChatEntity>>(
        ServerFailure(message: e.toString()),
      ),
    );
  }

  @override
  Stream<Either<Failure, List<DmMessageEntity>>> watchDmMessages(
    String chatId,
  ) {
    return _datasource.watchDmMessages(chatId).map(
      (models) => Either.right<Failure, List<DmMessageEntity>>(
        models.map((m) => m.toEntity()).toList(),
      ),
    ).handleError(
      (e) => Either.left<Failure, List<DmMessageEntity>>(
        ServerFailure(message: e.toString()),
      ),
    );
  }

  @override
  Future<Either<Failure, DmMessageEntity>> sendDmMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final model = await _datasource.sendDmMessage(
        chatId: chatId,
        content: content,
        replyToMessageId: replyToMessageId,
      );
      return Either.right(model.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDmMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _datasource.deleteDmMessage(chatId: chatId, messageId: messageId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editDmMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _datasource.editDmMessage(
        chatId: chatId,
        messageId: messageId,
        newContent: newContent,
      );
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DmChatEntity>> getDmChat(String chatId) async {
    try {
      final model = await _datasource.getDmChat(chatId);
      return Either.right(model.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }
}
