import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _obscure = true.obs;

  AuthController get _auth => Get.find<AuthController>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejoins PrixKlo 🌍',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral100,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aide ta communauté en signalant les prix abusifs.',
                style: TextStyle(fontSize: 15, color: AppColors.neutral60),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => TextField(
                    controller: _passCtrl,
                    obscureText: _obscure.value,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => _obscure.value = !_obscure.value,
                      ),
                    ),
                  )),
              const SizedBox(height: 32),
              Obx(() => ElevatedButton(
                    onPressed: _auth.isLoading.value
                        ? null
                        : () => _auth.register(
                            _nameCtrl.text, _emailCtrl.text, _passCtrl.text),
                    child: _auth.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Créer mon compte'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
