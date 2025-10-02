import 'package:flutter/material.dart';
import 'package:pos_azmi/services/pusher_service.dart';
import 'login_screen.dart';
import 'choose_outlet_screen.dart';
import 'main_menu_screen.dart';
import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/core/storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // Future<void> _initApp() async {
  //   await ApiClient.setup();
  //   await Future.delayed(const Duration(seconds: 1));

  //   final token = await Storage.getToken();
  //   final outlet = await Storage.getOutlet();

  //   if (!mounted) return;

  //   if (token == null) {
  //     _navigateTo(const LoginScreen());
  //   } else if (outlet == null) {
  //     _navigateTo(const ChooseOutletScreen());
  //   } else {
  //     _navigateTo(MainMenuScreen(outlet: outlet));
  //   }
  // }
  Future<void> _initApp() async {
    await ApiClient.setup();
    await Future.delayed(const Duration(seconds: 1));

    final token = await Storage.getToken();
    final outlet = await Storage.getOutlet();

    if (!mounted) return;

    if (token == null) {
      _navigateTo(const LoginScreen());
    } else if (outlet == null) {
      _navigateTo(const ChooseOutletScreen());
    } else {
      await PusherService().init(outletId: outlet.id);

      _navigateTo(MainMenuScreen(outlet: outlet));
    }
  }

  void _navigateTo(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
