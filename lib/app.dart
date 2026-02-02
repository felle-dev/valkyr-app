import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:valkyr/auth/auth.dart';

class valkyrApp extends StatelessWidget {
  const valkyrApp({Key? key}) : super(key: key);

  ThemeData _buildThemeData(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Outfit',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'NoyhR'),
        displayMedium: TextStyle(fontFamily: 'NoyhR'),
        displaySmall: TextStyle(fontFamily: 'NoyhR'),
        headlineLarge: TextStyle(fontFamily: 'NoyhR'),
        headlineMedium: TextStyle(fontFamily: 'NoyhR'),
        headlineSmall: TextStyle(fontFamily: 'NoyhR'),
        titleLarge: TextStyle(fontFamily: 'NoyhR'),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarBrightness: brightness == Brightness.light
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'valkyr',
          theme: _buildThemeData(lightColorScheme, Brightness.light),
          darkTheme: _buildThemeData(darkColorScheme, Brightness.dark),
          themeMode: ThemeMode.system,
          home: const AuthScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
