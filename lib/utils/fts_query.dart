/// Builds a query string suitable for SQLite FTS5 MATCH clause.
/// It splits the raw input into space-separated tokens, wraps each token in
/// double quotes, and appends `*` to the last token for prefix matching.
/// Example: "axle oi" -> '"axle" "oi"*'
String? buildFtsPrefixQuery(String rawInput) {
  final cleanInput = rawInput.trim();
  if (cleanInput.isEmpty) return null;

  final tokens = cleanInput.split(' ').where((t) => t.isNotEmpty).toList();
  if (tokens.isEmpty) return null;

  final formattedTokens = <String>[];
  for (int i = 0; i < tokens.length; i++) {
    // Escape double quotes inside the token by doubling them
    final escapedToken = tokens[i].replaceAll('"', '""');
    if (i == tokens.length - 1) {
      formattedTokens.add('"$escapedToken"*');
    } else {
      formattedTokens.add('"$escapedToken"');
    }
  }

  return formattedTokens.join(' ');
}
