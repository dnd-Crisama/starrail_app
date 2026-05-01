import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/create_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

// ── Dependency Injection Providers ─────────────────────────────

final _authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasourceImpl(auth: FirebaseAuth.instance);
});

final _userRemoteDatasourceProvider = Provider<UserRemoteDatasource>((ref) {
  return UserRemoteDatasourceImpl(firestore: FirebaseFirestore.instance);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authRemoteDatasource: ref.watch(_authRemoteDatasourceProvider),
    userRemoteDatasource: ref.watch(_userRemoteDatasourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final createProfileUseCaseProvider = Provider<CreateProfileUseCase>((ref) {
  return CreateProfileUseCase(ref.watch(authRepositoryProvider));
});

// ── State cho Auth ─────────────────────────────────────────────

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool needsProfileCreation;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.needsProfileCreation = false,
  });

  bool get isAuthenticated => user != null || needsProfileCreation;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool? needsProfileCreation,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      needsProfileCreation: needsProfileCreation ?? this.needsProfileCreation,
    );
  }
}

// ── Auth Notifier (Quản lý State) ──────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final CreateProfileUseCase _createProfileUseCase;
  final AuthRepository _authRepository;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required CreateProfileUseCase createProfileUseCase,
    required AuthRepository authRepository,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _logoutUseCase = logoutUseCase,
       _createProfileUseCase = createProfileUseCase,
       _authRepository = authRepository,
       super(const AuthState(isLoading: true)) {
    appStarted();
  }

  Future<void> appStarted() async {
    try {
      final userEntity = await _authRepository.getCurrentUser();
      state = state.copyWith(user: userEntity, isLoading: false);
    } catch (e) {
      if (e is CacheFailure) {
        state = state.copyWith(isLoading: false, needsProfileCreation: true);
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    state = result.fold(
      ifLeft: (failure) {
        if (failure is CacheFailure) {
          return state.copyWith(isLoading: false, needsProfileCreation: true);
        }
        return state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
      },
      ifRight: (user) => state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _registerUseCase(
      RegisterParams(email: email, password: password, username: username),
    );

    state = result.fold(
      ifLeft: (failure) => state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      ifRight: (user) => state.copyWith(isLoading: false, user: user),
    );
  }

  Future<void> createProfile({required String username}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _createProfileUseCase(
      CreateProfileParams(username: username),
    );

    state = result.fold(
      ifLeft: (failure) => state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      ifRight: (user) => state.copyWith(
        isLoading: false,
        user: user,
        needsProfileCreation: false,
      ),
    );
  }

  Future<void> logout() async {
    await _logoutUseCase(const NoParams());
    state = const AuthState();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is AuthFailure) return failure.message;
    if (failure is ServerFailure) return failure.message;
    return 'Đã xảy ra lỗi không xác định.';
  }

  void updateUserEntity(UserEntity newUser) {
    state = state.copyWith(user: newUser);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    createProfileUseCase: ref.watch(createProfileUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});
