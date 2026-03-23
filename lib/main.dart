import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poke_jerk_api/graphql/client.dart';
import 'package:poke_jerk_api/model/comparator_provider.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/team_provider.dart';
import 'package:poke_jerk_api/model/user_pokemons.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/user_team.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/home.dart';
import 'package:provider/provider.dart';

/// Opens a Hive box, recovering automatically if it is corrupted.
Future<Box<T>> _openBoxSafe<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (e) {
    debugPrint('Hive box "$name" corrupted, deleting and recreating: $e');
    await Hive.deleteBoxFromDisk(name);
    return await Hive.openBox<T>(name);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(UserPokemonsAdapter());
  Hive.registerAdapter(UserTeamAdapter());

  final boxUserSettings = await _openBoxSafe<UserSettings>('user_settings');
  final boxUserPokemons = await _openBoxSafe<UserPokemons>('user_pokemons');
  final boxUserTeams = await _openBoxSafe<UserTeam>('user_teams');
  await _openBoxSafe<dynamic>('pokedex_filters');

  if (boxUserSettings.isEmpty) {
    boxUserSettings.add(UserSettings());
  } else {
    UserSettings.initialize(boxUserSettings.values.first);
  }

  UserDatas().boxUserPokemons = boxUserPokemons;
  if (boxUserPokemons.isNotEmpty) {
    UserDatas().initUserPokemons();
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserSettings()),
      ChangeNotifierProvider(create: (_) => UserDatas()),
      ChangeNotifierProvider(create: (_) => GlobalFilterProvider()),
      ChangeNotifierProvider(create: (_) => TeamProvider()..init(boxUserTeams)),
      ChangeNotifierProvider(create: (_) => ComparatorProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Rouge Pokédex classique
  static const Color _red = Color(0xFFCC0000);
  // Fond quasi-noir pour la barre de navigation (base du Pokédex)
  static const Color _dark = Color(0xFF1A1A1A);
  // Fond général (écran du Pokédex)
  static const Color _bg = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserSettings>().darkMode;
    return GraphQLProvider(
      client: graphQLClient,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Poké Jerk API',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const Home(),
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    return _buildTheme(
      colorScheme: const ColorScheme.light(
        primary: _red,
        onPrimary: Colors.white,
        secondary: _dark,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: _dark,
        primaryContainer: Color(0xFFFFDAD6),
        onPrimaryContainer: _red,
        outline: Color(0xFFDDDDDD),
      ),
      scaffoldBg: _bg,
      cardColor: Colors.white,
      inputFill: Colors.white,
      inputBorder: const Color(0xFFDDDDDD),
      inputIcon: const Color(0xFF666666),
      inputHint: const Color(0xFF999999),
      divider: const Color(0xFFE8E8E8),
      navBg: _dark,
      chipSelected: _red.withValues(alpha: 0.12),
    );
  }

  static ThemeData _buildDarkTheme() {
    return _buildTheme(
      colorScheme: const ColorScheme.dark(
        primary: _red,
        onPrimary: Colors.white,
        secondary: Color(0xFFBBBBBB),
        onSecondary: Colors.black,
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFE0E0E0),
        primaryContainer: Color(0xFF5C0000),
        onPrimaryContainer: Color(0xFFFFB4AB),
        outline: Color(0xFF444444),
      ),
      scaffoldBg: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      inputFill: const Color(0xFF2A2A2A),
      inputBorder: const Color(0xFF444444),
      inputIcon: const Color(0xFF999999),
      inputHint: const Color(0xFF777777),
      divider: const Color(0xFF333333),
      navBg: const Color(0xFF0D0D0D),
      chipSelected: _red.withValues(alpha: 0.25),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color inputFill,
    required Color inputBorder,
    required Color inputIcon,
    required Color inputHint,
    required Color divider,
    required Color navBg,
    required Color chipSelected,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,

      // Police légèrement plus grande par défaut
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 15),
        bodySmall: TextStyle(fontSize: 13),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontSize: 15),
        labelMedium: TextStyle(fontSize: 13),
        labelSmall: TextStyle(fontSize: 12),
      ),

      // AppBar : rouge Pokédex, texte blanc
      appBarTheme: const AppBarTheme(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: _red,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        elevation: 8,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.grey,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.grey,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        isDense: true,
        prefixIconColor: inputIcon,
        suffixIconColor: inputIcon,
        hintStyle: TextStyle(color: inputHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 2),
        ),
      ),

      // TabBar : rouge pour l'onglet actif
      tabBarTheme: const TabBarThemeData(
        labelColor: _red,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _red,
        dividerColor: Color(0xFFEEEEEE),
      ),

      // FilterChip
      chipTheme: ChipThemeData(
        selectedColor: chipSelected,
        checkmarkColor: _red,
        side: const BorderSide(color: Color(0xFFDDDDDD)),
        labelStyle: const TextStyle(fontSize: 12),
      ),

      // Dividers
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, thickness: 1),

      // Bottom sheets & dialogs
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: cardColor),
      dialogTheme: DialogThemeData(backgroundColor: cardColor),

      // FAB rouge
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
