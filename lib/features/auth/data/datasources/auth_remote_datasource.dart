import 'package:firebase_auth/firebase_auth.dart' hide AuthException;
import '../../../../core/errors/exceptions.dart';

/// Giao tiếp trực tiếp với FirebaseAuth.
/// Chỉ Data layer được import Firebase.
abstract class AuthRemoteDatasource {
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });
  Future<UserCredential> signUp({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<User?> getCurrentFirebaseUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth auth;

  AuthRemoteDatasourceImpl({required this.auth});

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Login failed', code: e.code);
    }
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Registration failed',
        code: e.code,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
  }

  @override
  Future<User?> getCurrentFirebaseUser() async {
    return auth.currentUser;
  }
}
