import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos_azmi/helpers/attendance_auto.dart';
import 'package:pos_azmi/helpers/notifikasi_helper.dart';
import 'package:pos_azmi/services/auth_service.dart';
import 'choose_outlet_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void _login() async {
    final username = usernameCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showSnackbar(
        context,
        'Username dan Password wajib diisi',
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 20,
        ),
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await AuthService.login(username, password);

    setState(() => isLoading = false);

    if (success && context.mounted) {
      // kirim absensi otomatis
      AutoAttendance.submitAutoAbsensi();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChooseOutletScreen()),
      );
    } else {
      if (context.mounted) {
        showSnackbar(
          context,
          'Login gagal. Periksa kembali username dan password.',
          icon: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 80,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        TextField(
                          controller: usernameCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              dotenv.env['APP_DEV'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
