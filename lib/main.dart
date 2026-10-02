import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/navigation_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt safe initialization of Firebase (falls back to local/mock mode if not configured)
  await FirebaseConfig.initializeSafely();

  // Configure edge-to-edge transparent system overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SpendlyApp());
}

class SpendlyApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final TransactionProvider? transactionProvider;

  const SpendlyApp({
    super.key,
    this.authProvider,
    this.transactionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (_) => transactionProvider ?? TransactionProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Spendly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const NavigationShell(),
      ),
    );
  }
}
