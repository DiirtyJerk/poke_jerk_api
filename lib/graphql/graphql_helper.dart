import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

const Duration defaultQueryTimeout = Duration(seconds: 30);

/// Execute a GraphQL query with timeout and error handling.
/// Returns the parsed data via [parser], or throws on error.
Future<T> safeQuery<T>({
  required BuildContext context,
  required String query,
  required T Function(Map<String, dynamic> data) parser,
  Map<String, dynamic> variables = const {},
  FetchPolicy fetchPolicy = FetchPolicy.cacheAndNetwork,
  Duration timeout = defaultQueryTimeout,
  String tag = 'GraphQL',
}) async {
  final client = GraphQLProvider.of(context).value;
  debugPrint('[$tag] fetching...');

  final result = await client.query(QueryOptions(
    document: gql(query),
    variables: variables,
    fetchPolicy: fetchPolicy,
  )).timeout(timeout);

  debugPrint('[$tag] query OK');

  if (result.hasException) {
    throw result.exception!;
  }

  return parser(result.data!);
}
