import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pos_azmi/env/env_config.dart';
import 'package:pos_azmi/core/storage.dart';
import 'package:pos_azmi/core/api_client.dart';
import 'package:pos_azmi/core/theme.dart';
import 'package:pos_azmi/providers/cart_provider.dart';
import 'package:pos_azmi/providers/order_notifier.dart';
import 'package:pos_azmi/screens/kasir/success_screen.dart';
import 'package:pos_azmi/screens/location_permission_screen.dart';
import 'package:provider/provider.dart';
import 'services/pusher_service.dart';
import 'package:pos_azmi/core/navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const isProd = bool.fromEnvironment('dart.vm.product');
  await EnvConfig.load(isProd: isProd);

  await ApiClient.setup();

  final outlet = await Storage.getOutlet();
  final outletId = outlet?.id ?? 0;

  if (outletId > 0) {
    await PusherService().init(outletId: outletId);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: dotenv.env['APP_NAME'] ?? 'POS Azmi',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LocationPermissionScreen(),
      routes: {
        '/success': (context) => const SuccessScreen(),
      },
    );
  }
}
