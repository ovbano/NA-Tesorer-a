import 'package:supabase_flutter/supabase_flutter.dart';

/// Mensajes aptos para mostrar al usuario, sin exponer detalles internos.
String message(Object error) {
  if (error is FormatException) return error.message;
  if (error is AuthException) {
    return 'No se pudo iniciar o actualizar la sesión. '
        'Revisa tus credenciales y conexión.';
  }
  if (error is PostgrestException) {
    // Se conserva el mensaje de la RPC, que puede contener validaciones
    // financieras relevantes para el usuario.
    return error.message;
  }
  if (error is StorageException) {
    return 'No se pudo guardar o abrir el comprobante. '
        'Revisa tu conexión y vuelve a intentar.';
  }
  return 'No se pudo completar la operación. '
      'Comprueba tu conexión e intenta nuevamente.';
}
