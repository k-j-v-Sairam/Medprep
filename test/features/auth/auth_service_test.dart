import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:akpa/features/auth/application/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });

    test('signInWithEmailPassword success returns UserCredential', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('test@example.com');
      
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithEmailPassword('test@example.com', 'password123');

      expect(result, equals(mockCredential));
      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('signInWithEmailPassword throws friendly message on FirebaseAuthException', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'wrong',
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => authService.signInWithEmailPassword('test@example.com', 'wrong'),
        throwsA(equals('Incorrect password. Please try again.')),
      );
    });
  });
}
