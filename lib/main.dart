import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/beekeeper_provider.dart';
import 'providers/hive_provider.dart';
import 'views/auth/login_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Estilo visual da barra de status no padrão Apple/iOS
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MeliponaApp());
}

class MeliponaApp extends StatelessWidget {
  const MeliponaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BeekeeperProvider()),
        ChangeNotifierProvider(create: (_) => HiveProvider()),
      ],
      child: MaterialApp(
        title: 'MeliponaCare - Monitoramento de Colmeias',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginView(),
      ),
    );
  }
}
