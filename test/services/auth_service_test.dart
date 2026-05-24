import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Note: We'll create this file in the next step
import '../../lib/services/auth_service.dart'; 

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockGoogleSignInAuthorizationClient extends Mock implements GoogleSignInAuthorizationClient {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
  });

  late AuthService authService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    authService = AuthService(
      supabaseClient: mockSupabaseClient,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthService Tests', () {
    test('signInWithEmail must call Supabase signInWithPassword', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      when(() => mockGoTrueClient.signInWithPassword(
            email: 'test@test.com',
            password: 'password123',
          )).thenAnswer((_) async => mockResponse);

      // Act
      final response = await authService.signInWithEmail('test@test.com', 'password123');

      // Assert
      expect(response, mockResponse);
      verify(() => mockGoTrueClient.signInWithPassword(
            email: 'test@test.com',
            password: 'password123',
          )).called(1);
    });

    test('signUpWithEmail must call Supabase signUp', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      when(() => mockGoTrueClient.signUp(
            email: 'test@test.com',
            password: 'password123',
          )).thenAnswer((_) async => mockResponse);

      // Act
      final response = await authService.signUpWithEmail('test@test.com', 'password123');

      // Assert
      expect(response, mockResponse);
      verify(() => mockGoTrueClient.signUp(
            email: 'test@test.com',
            password: 'password123',
          )).called(1);
    });

    test('signInWithGoogle completes auth flow successfully', () async {
      // Arrange
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();
      final mockResponse = MockAuthResponse();
      final mockAuthClient = MockGoogleSignInAuthorizationClient();

      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authentication).thenReturn(mockAuth);
      when(() => mockAccount.authorizationClient).thenReturn(mockAuthClient);
      when(() => mockAuth.idToken).thenReturn('fake_id_token');
      when(() => mockAuthClient.authorizationForScopes(any()))
          .thenAnswer((_) async => null);
      
      when(() => mockGoTrueClient.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: 'fake_id_token',
            accessToken: null,
          )).thenAnswer((_) async => mockResponse);

      // Act
      final response = await authService.signInWithGoogle();

      // Assert
      expect(response, mockResponse);
      verify(() => mockGoogleSignIn.authenticate()).called(1);
      verify(() => mockAccount.authentication).called(1);
      verify(() => mockGoTrueClient.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: 'fake_id_token',
            accessToken: null,
          )).called(1);
    });

    test('signInWithGoogle returns null if user cancels dialog', () async {
      // Arrange
      when(() => mockGoogleSignIn.authenticate()).thenThrow(Exception('Canceled'));

      // Act
      final response = await authService.signInWithGoogle();

      // Assert
      expect(response, isNull);
      verify(() => mockGoogleSignIn.authenticate()).called(1);
      verifyNever(() => mockGoTrueClient.signInWithIdToken(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
            accessToken: any(named: 'accessToken'),
          ));
    });

    test('signOut must call Supabase signOut', () async {
      // Arrange
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.disconnect()).thenAnswer((_) async => null);

      // Act
      await authService.signOut();

      // Assert
      verify(() => mockGoTrueClient.signOut()).called(1);
      verify(() => mockGoogleSignIn.disconnect()).called(1);
    });
  });
}
