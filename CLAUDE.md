# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokéJerk is a Flutter Pokedex app that fetches data from the PokeAPI GraphQL beta endpoint (`https://beta.pokeapi.co/graphql/v1beta`). It supports French and English (language IDs 5 and 9 in PokeAPI). All GraphQL queries request both languages and models resolve translations via `getTranslation(language)` using `language == 'fr' ? 5 : 9`.

## Commands

```bash
flutter pub get                  # Install dependencies
flutter run                      # Run the app
flutter analyze                  # Static analysis (uses flutter_lints)
flutter test                     # Run tests
dart run build_runner build      # Generate Hive adapters (*.g.dart files)
```

## Architecture

### Data Layer
- **`lib/graphql/client.dart`** - Single GraphQL client using `graphql_flutter`, in-memory cache
- **`lib/graphql/queries.dart`** - All GraphQL query strings. Two factory patterns per model: `fromListJson` (list/card view, partial data) and `fromDetailJson` (detail view, full data)

### Models (`lib/model/`)
- **`pokemon.dart`** - Core model with `Pokemon`, `PokemonSpecies`, `PokemonForm`. Species holds evolution chain data
- **`user_settings.dart`** - Singleton with Hive persistence (`@HiveType(typeId: 0)`). Tracks language, showMega, showBattle, capturedFeature
- **`user_pokemons.dart`** - Hive model (`@HiveType(typeId: 1)`) for per-pokemon user state (selected/favorited/captured)
- **`users_datas.dart`** - `UserDatas` singleton managing the `UserPokemons` collection via Hive box
- **`global_filter.dart`** - `GlobalFilterProvider` (ChangeNotifier) loads types/generations/version groups once, persists filter selections to a Hive box (`pokedex_filters`)

### State Management
Three `ChangeNotifierProvider`s at root level (via `provider` package):
1. `UserSettings` - language and display preferences
2. `UserDatas` - user's pokemon collection state
3. `GlobalFilterProvider` - search, type/generation/version filters (shared across Pokedex/Items/Moves tabs)

### Local Storage
Hive with three boxes:
- `user_settings` - `UserSettings` object
- `user_pokemons` - `UserPokemons` entries keyed by pokemon identifier
- `pokedex_filters` - dynamic box for persisting filter state

When modifying Hive models, regenerate adapters with `dart run build_runner build`.

### UI (`lib/ui/`)
- **`home.dart`** - Main scaffold with bottom NavigationBar (4 tabs: Pokedex, Items, Moves, Settings), search bar, and filter chips (version/type/generation)
- **`pokedex.dart`** / **`items.dart`** / **`moves.dart`** - List pages consuming GraphQL queries
- **`detail_pokemon.dart`** / **`detail_item.dart`** / **`detail_move.dart`** - Detail pages
- **`widgets/`** - Reusable components (cards, badges, tabs, filter sheets)
- **`uiBuilder/colorbuilder.dart`** - Pokemon type-to-color mapping

### Conventions
- Bilingual support: all user-facing text checks `language == 'fr'` for French, falls back to English
- Sprite URLs use official artwork from PokeAPI GitHub sprites repo
- Models use `Map<int, String>` for localized name storage (key = PokeAPI language_id)
