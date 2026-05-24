import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_text.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Preencha e-mail e senha.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmail(email, password);
      // AuthGate vai interceptar a mudança de sessão e mudar a tela
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final response = await _authService.signInWithGoogle();
      if (response == null) {
        // Usuário cancelou ou falhou sem jogar exception
        if (mounted) setState(() => _isGoogleLoading = false);
      }
    } on AuthException catch (e) {
      _showError(e.message);
      if (mounted) setState(() => _isGoogleLoading = false);
    } catch (e) {
      _showError('Erro ao conectar com Google: $e');
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(message, color: Colors.white),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.restaurant, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                const AppText.title(
                  'GarfadaLog',
                  color: AppColors.primary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const AppText.subtitle(
                  'Acesse sua conta',
                  textAlign: TextAlign.center,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 48),
                CustomInput(
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomInput(
                  controller: _passwordController,
                  label: 'Senha',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Entrar',
                  onPressed: _isLoading || _isGoogleLoading ? () {} : _signInWithEmail,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AppText('OU', type: AppTextType.caption),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading || _isGoogleLoading ? null : _signInWithGoogle,
                  icon: _isGoogleLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login, color: Colors.red), // Simplificado para ícone comum
                  label: const AppText('Entrar com Google', bold: true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const AppText('Não tem uma conta? Cadastre-se', color: AppColors.primary, bold: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
