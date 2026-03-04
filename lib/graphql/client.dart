import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final HttpLink _httpLink = HttpLink('https://beta.pokeapi.co/graphql/v1beta');

ValueNotifier<GraphQLClient> graphQLClient = ValueNotifier(
  GraphQLClient(
    link: _httpLink,
    cache: GraphQLCache(store: InMemoryStore()),
  ),
);
