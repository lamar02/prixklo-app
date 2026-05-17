import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailCtrl = TextEditingController();
  final _loading = false.obs;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Champ requis', 'Entrez votre adresse email.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _loading.value = true;
    try {
      await Get.find<ApiService>().forgotPassword(email);
      // Réponse identique succès/échec pour ne pas révéler si le compte existe
      Get.snackbar(
        'Email envoyé',
        'Si ce compte existe, vous recevrez un lien de réinitialisation.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      Get.back();
    } catch (_) {
      Get.snackbar('Erreur', 'Problème de connexion. Réessayez.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Réinitialiser votre mot de passe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral100,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre adresse email. Si un compte existe, vous recevrez un lien de réinitialisation.',
                style: TextStyle(fontSize: 15, color: AppColors.neutral60, height: 1.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => ElevatedButton(
                    onPressed: _loading.value ? null : _submit,
                    child: _loading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Réinitialiser le mot de passe'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
