// Language IDs: French = 5, English = 9

const String getPokemonsQuery = r'''
query GetPokemons($limit: Int!, $offset: Int!, $where: pokemon_v2_pokemon_bool_exp!) {
  pokemon_v2_pokemon(
    limit: $limit
    offset: $offset
    order_by: {id: asc}
    where: $where
  ) {
    id
    name
    pokemon_v2_pokemontypes(order_by: {slot: asc}) {
      pokemon_v2_type {
        id
        name
        pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
    pokemon_v2_pokemonsprites {
      sprites
    }
    pokemon_v2_pokemonspecy {
      generation_id
      pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
  }
}
''';

const String getPokemonDetailQuery = r'''
query GetPokemonDetail($id: Int!) {
  pokemon_v2_pokemon_by_pk(id: $id) {
    id
    name
    height
    weight
    base_experience
    is_default
    pokemon_v2_pokemonstats {
      base_stat
      stat_id
      pokemon_v2_stat {
        name
        pokemon_v2_statnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
    pokemon_v2_pokemontypes(order_by: {slot: asc}) {
      pokemon_v2_type {
        id
        name
        pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
    pokemon_v2_pokemonmoves(order_by: {level: asc}) {
      level
      version_group_id
      pokemon_v2_versiongroup {
        id
        name
        generation_id
        pokemon_v2_versions {
          id
          name
          pokemon_v2_versionnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
      pokemon_v2_movelearnmethod {
        name
        pokemon_v2_movelearnmethodnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
      pokemon_v2_move {
        id
        name
        power
        pp
        accuracy
        pokemon_v2_movenames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
        pokemon_v2_movedamageclass {
          id
          name
          pokemon_v2_movedamageclassnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
        pokemon_v2_type {
          id
          name
          pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
    }
    pokemon_v2_pokemonspecy {
      id
      name
      generation_id
      evolution_chain_id
      is_legendary
      is_mythical
      is_baby
      gender_rate
      capture_rate
      pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
        name
        genus
        language_id
      }
      pokemon_v2_pokemons(order_by: {id: asc}) {
        id
        name
        is_default
        pokemon_v2_pokemonforms(limit: 1) {
          form_name
          pokemon_v2_pokemonformnames(where: {language_id: {_in: [5, 9]}}) {
            name
            pokemon_name
            language_id
          }
        }
        pokemon_v2_pokemontypes(order_by: {slot: asc}) {
          pokemon_v2_type {
            id
            name
            pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
              name
              language_id
            }
          }
        }
      }
      pokemon_v2_evolutionchain {
        pokemon_v2_pokemonspecies(order_by: {id: asc}) {
          id
          name
          generation_id
          evolves_from_species_id
          pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
          pokemon_v2_pokemondexnumbers {
            pokedex_id
          }
          pokemon_v2_pokemons(order_by: {id: asc}) {
            id
            is_default
            pokemon_v2_pokemontypes(order_by: {slot: asc}) {
              pokemon_v2_type {
                id
                name
                pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
                  name
                  language_id
                }
              }
            }
            pokemon_v2_pokemonforms(limit: 1) {
              form_name
            }
          }
          pokemon_v2_pokemonevolutions {
            id
            evolved_species_id
            min_level
            min_happiness
            min_beauty
            min_affection
            gender_id
            time_of_day
            needs_overworld_rain
            turn_upside_down
            relative_physical_stats
            pokemon_v2_evolutiontrigger {
              name
              pokemon_v2_evolutiontriggernames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemon_v2_item {
              id
              name
              pokemon_v2_itemnames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemonV2ItemByHeldItemId {
              id
              name
              pokemon_v2_itemnames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemon_v2_location {
              id
              name
              pokemon_v2_locationnames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemon_v2_move {
              id
              name
              pokemon_v2_movenames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemon_v2_type {
              id
              name
              pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemonV2TypeByPartyTypeId {
              id
              name
              pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemonV2PokemonspecyByPartySpeciesId {
              id
              name
              pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
            pokemonV2PokemonspecyByTradeSpeciesId {
              id
              name
              pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
                name
                language_id
              }
            }
          }
        }
      }
    }
    pokemon_v2_pokemonforms(where: {is_default: {_eq: false}}) {
      id
      name
      is_battle_only
      is_mega
      pokemon_v2_pokemonformnames(where: {language_id: {_in: [5, 9]}}) {
        name
        pokemon_name
        language_id
      }
    }
    pokemon_v2_encounters {
      encounter_slot_id
      min_level
      max_level
      pokemon_v2_version {
        id
        name
        pokemon_v2_versionnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
      pokemon_v2_locationarea {
        pokemon_v2_location {
          id
          name
          pokemon_v2_locationnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
      pokemon_v2_encounterslot {
        rarity
        pokemon_v2_encountermethod {
          name
          pokemon_v2_encountermethodnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
    }
  }
}
''';

const String getItemsQuery = r'''
query GetItems {
  pokemon_v2_item(order_by: {id: asc}) {
    id
    name
    cost
    pokemon_v2_itemnames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
    pokemon_v2_itemcategory {
      name
      pokemon_v2_itemcategorynames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_itemflavortexts(where: {language_id: {_in: [5, 9]}}, limit: 1) {
      flavor_text
      language_id
    }
    pokemon_v2_itemgameindices {
      generation_id
    }
  }
}
''';

const String getMovesQuery = r'''
query GetMoves {
  pokemon_v2_move(order_by: {id: asc}) {
    id
    name
    power
    pp
    accuracy
    priority
    pokemon_v2_movenames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
    pokemon_v2_type {
      id
      name
      pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_movedamageclass {
      id
      name
      pokemon_v2_movedamageclassnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_generation {
      id
      name
    }
  }
}
''';

const String getMoveDetailQuery = r'''
query GetMoveDetail($moveId: Int!, $pokemonMovesWhere: pokemon_v2_pokemonmove_bool_exp!) {
  pokemon_v2_move_by_pk(id: $moveId) {
    id
    name
    power
    pp
    accuracy
    priority
    pokemon_v2_movenames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
    pokemon_v2_type {
      id
      name
      pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_movedamageclass {
      id
      name
      pokemon_v2_movedamageclassnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_moveflavortexts(where: {language_id: {_in: [5, 9]}}, order_by: {version_group_id: desc}, limit: 2) {
      flavor_text
      language_id
    }
    pokemon_v2_pokemonmoves(distinct_on: pokemon_id, order_by: [{pokemon_id: asc}], where: $pokemonMovesWhere) {
      pokemon_v2_pokemon {
        id
        name
        pokemon_v2_pokemonspecy {
          pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
        pokemon_v2_pokemontypes(order_by: {slot: asc}) {
          pokemon_v2_type {
            id
            name
            pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
              name
              language_id
            }
          }
        }
      }
    }
  }
}
''';

const String getGenerationsQuery = r'''
query GetGenerations {
  pokemon_v2_generation(order_by: {id: asc}) {
    id
    name
    pokemon_v2_generationnames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
  }
}
''';

const String getVersionGroupsQuery = r'''
query GetVersionGroups {
  pokemon_v2_pokedex(
    where: {is_main_series: {_eq: true}}
    order_by: {id: asc}
  ) {
    id
    pokemon_v2_pokedexnames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
    pokemon_v2_pokedexversiongroups {
      pokemon_v2_versiongroup {
        id
        name
        generation_id
        pokemon_v2_versions(order_by: {id: asc}) {
          id
          name
          pokemon_v2_versionnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
    }
  }
}
''';

const String getPokemonsByPokedexQuery = r'''
query GetPokemonsByPokedex($pokedexId: Int!) {
  pokemon_v2_pokemondexnumber(
    where: { pokedex_id: { _eq: $pokedexId } }
    order_by: { pokedex_number: asc }
  ) {
    pokedex_number
    pokemon_v2_pokemonspecy {
      generation_id
      pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
      pokemon_v2_pokemons(order_by: {is_default: desc}) {
        id
        name
        is_default
        pokemon_v2_pokemonforms(limit: 1) {
          form_name
        }
        pokemon_v2_pokemontypes(order_by: {slot: asc}) {
          pokemon_v2_type {
            id
            name
            pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
              name
              language_id
            }
          }
        }
        pokemon_v2_pokemonsprites {
          sprites
        }
      }
    }
  }
}
''';

const String getTypesQuery = r'''
query GetTypes {
  pokemon_v2_type(where: {id: {_lt: 19}}, order_by: {id: asc}) {
    id
    name
    pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
  }
}
''';

const String getItemDetailQuery = r'''
query GetItemDetail($itemId: Int!) {
  pokemon_v2_item_by_pk(id: $itemId) {
    id
    name
    cost
    fling_power
    pokemon_v2_itemnames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
    pokemon_v2_itemcategory {
      name
      pokemon_v2_itemcategorynames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_itemeffecttexts(where: {language_id: {_in: [5, 9]}}) {
      short_effect
      language_id
    }
    pokemon_v2_itemflavortexts(where: {language_id: {_in: [5, 9]}}, order_by: {version_group_id: desc}, limit: 1) {
      flavor_text
      language_id
    }
    pokemon_v2_itemgameindices {
      generation_id
      pokemon_v2_generation {
        pokemon_v2_generationnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
    pokemon_v2_pokemonitems {
      rarity
      pokemon_v2_version {
        id
        name
        pokemon_v2_versionnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
      pokemon_v2_pokemon {
        id
        name
        pokemon_v2_pokemonspecy {
          pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
        pokemon_v2_pokemontypes(order_by: {slot: asc}) {
          pokemon_v2_type {
            id
            name
            pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
              name
              language_id
            }
          }
        }
      }
    }
    pokemon_v2_machines {
      machine_number
      pokemon_v2_move {
        id
        name
        pokemon_v2_movenames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
        pokemon_v2_type {
          id
          name
          pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
      pokemon_v2_versiongroup {
        id
        name
        pokemon_v2_versions {
          name
          pokemon_v2_versionnames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
    }
  }
}
''';

const String getTeamPokemonDataQuery = r'''
query GetTeamPokemonData($ids: [Int!]!) {
  pokemon_v2_pokemon(where: {id: {_in: $ids}}, order_by: {id: asc}) {
    id
    name
    pokemon_v2_pokemonstats {
      base_stat
      pokemon_v2_stat {
        id
        name
        pokemon_v2_statnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
    pokemon_v2_pokemontypes(order_by: {slot: asc}) {
      pokemon_v2_type {
        id
        name
        pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
    pokemon_v2_pokemonspecy {
      pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
  }
}
''';

const String getLocationsQuery = r'''
query GetLocations {
  pokemon_v2_location(
    where: {pokemon_v2_locationareas: {pokemon_v2_encounters: {id: {_is_null: false}}}}
    order_by: {pokemon_v2_region: {id: asc}, id: asc}
  ) {
    id
    name
    pokemon_v2_region {
      id
      name
      pokemon_v2_regionnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_locationnames(where: {language_id: {_in: [5, 9]}}) {
      name
      language_id
    }
    pokemon_v2_locationareas {
      pokemon_v2_encounters {
        version_id
      }
    }
  }
}
''';

const String getLocationDetailQuery = r'''
query GetLocationDetail($locationId: Int!) {
  pokemon_v2_encounter(
    where: {pokemon_v2_locationarea: {location_id: {_eq: $locationId}}}
    order_by: {pokemon_id: asc}
  ) {
    pokemon_id
    encounter_slot_id
    min_level
    max_level
    pokemon_v2_pokemon {
      id
      name
      pokemon_v2_pokemonspecy {
        pokemon_v2_pokemonspeciesnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
      pokemon_v2_pokemontypes(order_by: {slot: asc}) {
        pokemon_v2_type {
          id
          name
          pokemon_v2_typenames(where: {language_id: {_in: [5, 9]}}) {
            name
            language_id
          }
        }
      }
    }
    pokemon_v2_version {
      id
      name
      pokemon_v2_versionnames(where: {language_id: {_in: [5, 9]}}) {
        name
        language_id
      }
    }
    pokemon_v2_encounterslot {
      rarity
      pokemon_v2_encountermethod {
        name
        pokemon_v2_encountermethodnames(where: {language_id: {_in: [5, 9]}}) {
          name
          language_id
        }
      }
    }
  }
}
''';
