import 'package:faramas/providers/booking.dart';
import 'package:faramas/providers/tour_request_provider.dart';
import 'package:faramas/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // Ensure Flutter widgets are initialized before accessing native features like SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Create an instance of AuthProvider
  final authProvider = AuthProvider();

  /*
    Load the authentication state from SharedPreferences
    This will set _user, _accessToken, _refreshToken based on stored data
    and attempt to refresh the token if the access token is expired.
    await authProvider.loadAuthState();
  */

  // Create an instance of LanguageProvider
  final languageProvider = LanguageProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FavoritesProvider>(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider<TourRequestProvider>(create: (_) => TourRequestProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
      child: const FaramasApp(),
    ),
  );
}

class FaramasApp extends StatelessWidget {
  const FaramasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'FARAMAS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0047AB)),
            useMaterial3: true,
          ),
          // Localization configuration
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('sw'), // Kiswahili
          ],
          // The initialRoute should now point to a splash screen
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.pages,
        );
      },
    );
  }
}
