import 'dart:convert';

/// Verifica exclusivamente la forma de una clave pública de Supabase.
/// NO certifica la autenticidad ni la validez criptográfica del token.
bool isPublicKey(String key) {
  final trimmed = key.trim();
  if (trimmed.startsWith('sb_publishable_')) return true;

  try {
    final pieces = trimmed.split('.');
    if (pieces.length != 3) return false;
    final decoded = utf8.decode(
      base64Url.decode(base64Url.normalize(pieces[1])),
    );
    final payload = jsonDecode(decoded);
    return payload is Map && payload['role'] == 'anon';
  } catch (_) {
    return false;
  }
}
