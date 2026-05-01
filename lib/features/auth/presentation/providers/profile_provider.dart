import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/update_status_usecase.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/datasources/cloudinary_storage_datasource.dart';
import '../../data/datasources/storage_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import 'auth_provider.dart';

final _storageDatasourceProvider = Provider<StorageRemoteDatasource>((ref) {
  return CloudinaryStorageDatasource();
});

final _userRepoProvider = Provider<UserRepository>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return UserRepositoryImpl(
    userRemoteDatasource: UserRemoteDatasourceImpl(
      firestore: FirebaseFirestore.instance,
    ),
    storageRemoteDatasource: ref.watch(_storageDatasourceProvider),
    currentUserId: currentUserId,
  );
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(_userRepoProvider));
});

final updateStatusUseCaseProvider = Provider<UpdateStatusUseCase>((ref) {
  return UpdateStatusUseCase(ref.watch(_userRepoProvider));
});

class ProfileState {
  final UserEntity? user;
  final bool isUpdating;
  final String? errorMessage;

  const ProfileState({this.user, this.isUpdating = false, this.errorMessage});

  ProfileState copyWith({
    UserEntity? user,
    bool? isUpdating,
    String? errorMessage,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final UpdateProfileUseCase _updateProfileUseCase;
  final UpdateStatusUseCase _updateStatusUseCase;
  final StorageRemoteDatasource _storageDatasource;
  final Ref _ref;

  ProfileNotifier({
    required UpdateProfileUseCase updateProfileUseCase,
    required UpdateStatusUseCase updateStatusUseCase,
    required StorageRemoteDatasource storageDatasource,
    required Ref ref,
  }) : _updateProfileUseCase = updateProfileUseCase,
       _updateStatusUseCase = updateStatusUseCase,
       _storageDatasource = storageDatasource,
       _ref = ref,
       super(const ProfileState());

  Future<void> updateAvatar(XFile imageFile) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final imageUrl = await _storageDatasource.uploadImage(imageFile);
      final result = await _updateProfileUseCase(
        UpdateProfileParams(avatarUrl: imageUrl),
      );

      result.fold(
        ifLeft: (failure) => state = state.copyWith(
          isUpdating: false,
          errorMessage: failure.message,
        ),
        ifRight: (updatedUser) {
          state = state.copyWith(isUpdating: false, user: updatedUser);
          _syncAuthState(updatedUser);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'Lỗi upload ảnh: $e',
      );
    }
  }

  Future<void> updateInfo({String? username, String? bio}) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);

    final result = await _updateProfileUseCase(
      UpdateProfileParams(username: username, bio: bio),
    );

    result.fold(
      ifLeft: (failure) => state = state.copyWith(
        isUpdating: false,
        errorMessage: failure.message,
      ),
      ifRight: (updatedUser) {
        state = state.copyWith(isUpdating: false, user: updatedUser);
        _syncAuthState(updatedUser);
      },
    );
  }

  Future<void> updatePresenceStatus(UserStatus status) async {
    final result = await _updateStatusUseCase(
      UpdateStatusParams(status: status),
    );
    result.fold(
      ifLeft: (failure) => null,
      ifRight: (_) {
        if (state.user != null) {
          final updatedUser = state.user!.copyWith(status: status);
          state = state.copyWith(user: updatedUser);
          _syncAuthState(updatedUser);
        }
      },
    );
  }

  void _syncAuthState(UserEntity updatedUser) {
    _ref.read(authNotifierProvider.notifier).updateUserEntity(updatedUser);
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      return ProfileNotifier(
        updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
        updateStatusUseCase: ref.watch(updateStatusUseCaseProvider),
        storageDatasource: ref.watch(_storageDatasourceProvider),
        ref: ref,
      );
    });
