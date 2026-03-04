import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:poke_jerk_api/graphql/client.dart';
import 'package:poke_jerk_api/model/global_filter.dart';
import 'package:poke_jerk_api/model/user_pokemons.dart';
import 'package:poke_jerk_api/model/user_settings.dart';
import 'package:poke_jerk_api/model/users_datas.dart';
import 'package:poke_jerk_api/ui/home.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(UserPokemonsAdapter());

  final boxUserSettings = await Hive.openBox<UserSettings>('user_settings');
  final boxUserPokemons = await Hive.openBox<UserPokemons>('user_pokemons');
  await Hive.openBox<dynamic>('pokedex_filters');

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
    return GraphQLProvider(
      client: graphQLClient,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Poké Jerk API',
        theme: _buildTheme(),
        home: const Home(),
      ),
    );
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
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
      scaffoldBackgroundColor: _bg,

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

      // NavigationBar : fond noir, indicateur rouge, icônes blanches
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _dark,
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

      // Cartes blanches
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Champs de recherche
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        // Force les icônes à être sombres même dans l'AppBar rouge
        prefixIconColor: const Color(0xFF666666),
        suffixIconColor: const Color(0xFF666666),
        hintStyle: const TextStyle(color: Color(0xFF999999)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
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

      // FilterChip : sélection rouge
      chipTheme: ChipThemeData(
        selectedColor: _red.withValues(alpha: 0.12),
        checkmarkColor: _red,
        side: const BorderSide(color: Color(0xFFDDDDDD)),
        labelStyle: const TextStyle(fontSize: 12),
      ),

      // Séparateurs légers
      dividerColor: const Color(0xFFE8E8E8),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8E8E8), thickness: 1),

      // FAB rouge
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
