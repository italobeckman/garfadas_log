import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthService({
    SupabaseClient? supabaseClient,
    GoogleSignIn? googleSignIn,
  })  : _supabaseClient = supabaseClient ?? Supabase.instance.client,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Se for Web, ignoramos a SDK nativa do Google e usamos o fluxo direto de redirecionamento do Supabase
      if (kIsWeb) {
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.toString(),
        );
        return null; // O navegador será redirecionado para a tela de login do Google
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Falha ao recuperar ID Token do Google.');
      }

      // Em v7.0+, a autorização é separada. Supabase geralmente só precisa do idToken para OIDC.
      // Se accessToken for estritamente necessário, teríamos que chamar authorizationClient.authorizeScopes([])
      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient.authorizationForScopes([]);
        accessToken = authz?.accessToken;
      } catch (_) {}

      return await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      // Usuário cancelou ou falhou
      print('Erro detalhado no Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    // Deslogar também no provedor do Google para limpar o cache da conta selecionada
    await _googleSignIn.disconnect();
  }
}
