import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  // Define available themes
  static final Map<String, Color> _themes = {
    'Dynamic': Colors.transparent, // Special marker for Material You
    'Indigo': Colors.indigo,
    'Blue': Colors.blue,
    'Teal': Colors.teal,
    'Green': Colors.green,
    'Purple': Colors.purple,
    'Pink': Colors.pink,
    'Red': Colors.red,
    'Orange': Colors.orange,
  };

  String _themeName = 'Blue';
  Color _primaryColor = Colors.blue;
  bool _isDarkMode = true;

  // Dynamic system ColorSchemes
  ColorScheme? _lightDynamic;
  ColorScheme? _darkDynamic;

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;
  String get themeName => _themeName;
  Map<String, Color> get availableThemes => _themes;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeName = prefs.getString(_themeKey) ?? 'Blue';
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    
    if (_themes.containsKey(_themeName)) {
      _primaryColor = _themes[_themeName]!;
    } else {
      _themeName = 'Blue';
      _primaryColor = Colors.blue;
    }
    
    notifyListeners();
  }

  void updateDynamicColors(ColorScheme? light, ColorScheme? dark) {
    if (_lightDynamic != light || _darkDynamic != dark) {
      _lightDynamic = light;
      _darkDynamic = dark;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> setTheme(String themeName) async {
    if (_themes.containsKey(themeName)) {
      _themeName = themeName;
      _primaryColor = _themes[themeName]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeName);
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    final bool isDark = _isDarkMode;
    
    // Check if dynamic color scheme is available and chosen
    final ColorScheme baseColorScheme;
    if (_themeName == 'Dynamic' && (_isDarkMode ? _darkDynamic : _lightDynamic) != null) {
      baseColorScheme = _isDarkMode ? _darkDynamic! : _lightDynamic!;
    } else {
      // Fallback or seed color theme scheme
      baseColorScheme = ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: isDark ? const Color(0xFF0A0B10) : const Color(0xFFFAFAFD),
      );
    }

    final Color primaryColor = baseColorScheme.primary;
    final Color surfaceColor = baseColorScheme.surface;
    final Color textPrimaryColor = isDark ? const Color(0xFFF1F2F6) : const Color(0xFF0B0C10);
    final Color textSecondaryColor = isDark ? const Color(0xFF8C92AC) : const Color(0xFF5A607F);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: surfaceColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF10111A) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13),
            width: 1,
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: baseColorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF10111A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 20.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(13),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: primaryColor.withAlpha(120), width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textSecondaryColor),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: baseColorScheme.onPrimary,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
