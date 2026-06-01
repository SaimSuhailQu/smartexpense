
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'firebase_options.dart';
import 'screens/create_account_screen.dart';
import 'screens/enhanced_login_screen.dart';
import 'screens/professional_dashboard_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/email_verification_screen.dart';

import 'services/auth_service.dart';
import 'services/categorizer_service.dart';
import 'services/expense_service.dart';
import 'services/notification_service.dart';
import 'services/currency_service.dart';
import 'services/loan_service.dart';
import 'services/income_service.dart';
import 'services/google_drive_service.dart';
import 'services/theme_service.dart';
import 'services/income_categorizer_service.dart';
import 'services/budget_service.dart';
import 'services/recurring_transaction_service.dart';
import 'services/currency_conversion_service.dart';

// Helper function to get device locale or fallback to default
Locale getPreferredLocale() {
  final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
  // Validate that we have a proper locale
  if (platformLocale.languageCode.isNotEmpty) {
    return platformLocale;
  }
  // Fallback to English
  return const Locale('en', '');
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Skip Firebase initialization on Linux as it's not supported
  if (!Platform.isLinux) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set default language for Firebase to prevent X-Firebase-Locale warnings
      final locale = getPreferredLocale();
      try {
        await FirebaseAuth.instance.setLanguageCode(locale.languageCode);
      } catch (e) {
        debugPrint('Failed to set Firebase language code: $e');
        // Fallback to English
        try {
          await FirebaseAuth.instance.setLanguageCode('en');
        } catch (fallbackError) {
          debugPrint('Failed to set Firebase language code to English: $fallbackError');
        }
      }
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Continue with app initialization even if Firebase fails
    }
  }

  // ✅ Initialize time zones for local notifications
  tz.initializeTimeZones();

  // ✅ Initialize and schedule notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  // Skip scheduling on Linux as zonedSchedule is not implemented
  if (!Platform.isLinux) {
    await notificationService.scheduleDailyReminder();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CategorizerService()),
        Provider(create: (_) => CurrencyConversionService()),
        ChangeNotifierProxyProvider<AuthService, GoogleDriveService>(
          create: (context) => GoogleDriveService(context.read<AuthService>(), context.read<CategorizerService>()),
          update: (context, authService, previous) => GoogleDriveService(authService, context.read<CategorizerService>()),
        ),
        ChangeNotifierProvider(create: (context) => CurrencyService()),
        ChangeNotifierProxyProvider2<CurrencyService, CurrencyConversionService, ExpenseService>(
          create: (context) => ExpenseService(context.read<CurrencyService>(), context.read<CurrencyConversionService>()),
          update: (context, currencyService, conversionService, previous) {
            return ExpenseService(currencyService, conversionService);
          },
        ),
        ChangeNotifierProxyProvider2<CurrencyService, CurrencyConversionService, IncomeService>(
          create: (context) => IncomeService(context.read<CurrencyService>(), context.read<CurrencyConversionService>()),
          update: (context, currencyService, conversionService, previous) {
            return IncomeService(currencyService, conversionService);
          },
        ),
        ChangeNotifierProxyProvider2<CurrencyService, CurrencyConversionService, LoanService>(
          create: (context) => LoanService(context.read<CurrencyService>(), context.read<CurrencyConversionService>()),
          update: (context, currencyService, conversionService, previous) {
            return LoanService(currencyService, conversionService);
          },
        ),
        ChangeNotifierProvider(create: (_) => IncomeCategorizerService()),
        ChangeNotifierProvider(create: (_) => BudgetService()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider.value(value: notificationService),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            themeService.updateDynamicColors(lightDynamic, darkDynamic);
            
            return MaterialApp(
              title: 'SmartExpense',
              theme: themeService.currentTheme,
              darkTheme: themeService.currentTheme,
              themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const AuthWrapper(),
              routes: {
                '/login': (context) => const EnhancedLoginScreen(),
                '/create_account': (context) => const CreateAccountScreen(),
                '/welcome': (context) => const WelcomeScreen(),
                '/email_verification': (context) => const EmailVerificationScreen(),
                '/dashboard': (context) => const ProfessionalDashboardScreen(),
              },
              // Add localization support to prevent X-Firebase-Locale warnings
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''), // English
                // Add other locales as needed
              ],
            );
          },
        );
      }
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    // On Linux, Firebase is not available, so skip authentication and go directly to dashboard
    if (Platform.isLinux) {
      return const ProfessionalDashboardScreen();
    }

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return _buildUserScreen(snapshot.data!);
        }

        return const WelcomeScreen();
      },
    );
  }

  Widget _buildUserScreen(User user) {
    final isGoogleUser =
        user.providerData.any((p) => p.providerId == 'google.com');

    // If email is not verified (and not a Google user), show verification screen.
    if (!user.emailVerified && !isGoogleUser) {
      return const EmailVerificationScreen();
    }

    // Otherwise, the user is authenticated and verified.
    return const ProfessionalDashboardScreen();
  }
}
