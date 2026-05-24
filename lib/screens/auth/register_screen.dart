import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/app_text.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Preencha todos os campos.');
      return;
    }

    if (password != confirmPassword) {
      _showError('As senhas não coincidem.');
      return;
    }

    if (password.length < 6) {
      _showError('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmail(email, password);
      
      if (!mounted) return;
      
      // Mostrar mensagem pedindo pra confirmar o email
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const AppText('Conta Criada!', bold: true),
          content: const AppText(
            'Enviamos um link de confirmação para o seu e-mail. Você precisa clicar nele antes de fazer o primeiro login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha dialog
                Navigator.of(context).pop(); // Volta pro login
              },
              child: const AppText('Entendi', color: AppColors.primary, bold: true),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(
        title: const AppText('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText.subtitle(
                'Preencha os dados abaixo para começar a salvar suas garfadas.',
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 16),
              CustomInput(
                controller: _confirmPasswordController,
                label: 'Confirmar Senha',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Cadastrar',
                onPressed: _isLoading ? () {} : _signUp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
