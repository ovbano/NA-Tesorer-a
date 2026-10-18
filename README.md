# NA · Tesorería de Amigos Verdaderos

Aplicación Flutter / Dart independiente de la web. Esta integración conserva el nombre `na_tesoreria`, la estructura Android y el applicationId del proyecto que ya se probó en un teléfono.

## Probar esta actualización desde Git Bash

Abre **Git Bash Here** dentro de tu proyecto (donde está `pubspec.yaml`).
Como se rehízo el historial, esta rama permite probar la actualización sin mezclar los commits locales antiguos:

```bash
git status --short
git fetch origin
git switch --create rediseno-tesoreria --track origin/codex/mobile-experience-refresh
flutter pub get
flutter test
flutter run
```

La primera vez crea la rama local; para actualizarla después usa `git pull --ff-only`.

Si tienes cambios locales, guárdalos en un commit antes del pull. No uses `git reset --hard` ni borres tu carpeta para actualizar. Si hay varios dispositivos, elige el Android físico o usa `flutter run -d ID_DEL_TELEFONO` con el ID que muestra `flutter devices`.

No necesitas crear nuevamente el proyecto, ejecutar scripts Python ni ingresar otra vez los saldos. El código trae la URL y **clave pública** que ya utiliza la web en `lib/supabase_config.dart`. El usuario entra con sus credenciales actuales; las tablas, fotos y movimientos son los mismos de Supabase.

La aplicación rechaza claves administrativas. No coloques `service_role`, `sb_secret_` ni contraseñas de la base en ningún archivo del frontend.

## Compilar la APK

```bash
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Es una instalación de prueba firmada con la clave de depuración, no un lanzamiento firmado para Play Store. Cuando la pruebes podremos configurar la firma de distribución y el icono definitivo.

## Compatibilidad

- Admite la instalación existente Flutter 3.28 master / Dart 3.7 pre del proyecto, y Flutter stable 3.29 o posterior que resuelva las dependencias declaradas. Se prefieren versiones estables al distribuir.
- Dependencias directas fijadas en versiones compatibles con Dart 3.7. La localización es de Flutter y no obliga a actualizar `intl` por separado.
- `flutter pub get` actualizará el lockfile inicial del proyecto con las dependencias de Tesorería. Después de la primera compilación correcta, conserva `pubspec.lock` en git.
- El manifiesto contiene permiso de internet y la app mantiene el identificador Android `com.example.na_tesoreria`.
- Mantén la ruta de compilación en Windows sin tildes ni caracteres especiales, por ejemplo `Desktop/NA-Tesoreria`.

## Funciones integradas

- Acceso con correo/contraseña, sesión de Supabase, perfil activo y roles administrador / tesorería / auditor.
- Perfil, cierre de sesión local y cambio de contraseña con confirmación.
- Resumen del período y fondos general/local. Las deudas y borradores no se suman al disponible.
- Ingresos/egresos, categoría, fecha, fondo y detalle; selección de compañeros con búsqueda para aportes del local.
- Borradores en Supabase; completar, corregir y anular con motivo usando las RPC existentes y sus controles de versión.
- Cámara/galería, optimización al capturar, almacenamiento privado y visualización de comprobantes.
- Registrar/corregir fondos iniciales. El backend recalcula saldos y conserva auditoría.
- Aportes individuales de todos los compañeros registrados, deuda acumulada de meses anteriores, filtros y desglose de cuotas/abonos por mes. Pendientes de actividades, crear/corregir deuda y recibir pagos. Los pagos se incorporan una sola vez al fondo general mediante la RPC de actividades.
- Cerrar el mes contrastando dinero contado con calculado; reabrir con motivo mediante la misma operación de la web.
- PDF con ingresos y egresos separados, resumen por fondos, aportes individuales y fotografías opcionales. Se descarga evidencia secuencialmente y se limita la memoria destinada a las fotos. Si alguna falla, el PDF indica consultar el original.
- Últimos 50 eventos de auditoría y acceso al panel web del administrador.

Todavía se utiliza la web para crear/desactivar usuarios, corregir y finalizar participaciones de los compañeros y consultar la auditoría completa. Ese panel mantiene su propio inicio de sesión en el navegador. No hay funcionamiento offline: los borradores y las fotos se guardan en Supabase con conexión. Logo/icono definitivo pendientes.

## Aportes individuales y deuda acumulada

- Todos los compañeros del registro aparecen, aunque nunca hayan pagado. El enlace usa `source_anniversary_id`, no una comparación de nombres.
- Las cifras proceden de `treasury_dues_history(p_month)`, la misma función de la web. No se crean deudas ni se suman cuotas pendientes al efectivo desde el teléfono.
- **Deuda anterior** reúne los pendientes anteriores al mes consultado. **Pendiente del mes** muestra lo que falta de esa cuota. **Total** suma ambos.
- **Por configurar** indica que falta confirmar desde qué mes corresponde la cuota. Administrador o tesorería pueden abrir **Configurar inicio**, elegir el mes y confirmar la cuota (sugerencia: USD 12). No se inventan fechas de ingreso. El servidor mantiene las protecciones de meses cerrados.
- En **Ver meses y abonos** se ven las cuotas y pagos de cada mes. En el mes actual abierto, **Registrar abono a este mes** abre el editor con el compañero, el mes adeudado y el pendiente precargados. Se puede cambiar el importe para registrar un abono parcial.
- La fecha del movimiento es la fecha real de recepción; el mes del aporte es la obligación que cancela. Un pago recibido hoy para septiembre ingresa hoy en caja y reduce septiembre en el historial actual; no cambia la foto del cierre de septiembre.
- Al consultar períodos históricos se deshabilita el cobro directo. Usa **Ir al mes actual para recibir abonos**, así no cobras de nuevo una deuda que quizá se pagó después del corte histórico.
- Los excedentes de una cuota no se asignan automáticamente a otras. Las obligaciones pendientes se conservan cuando termina la participación.
- El PDF conserva ingresos y egresos separados y muestra el **Anexo privado · Aportes para arriendo** con deuda anterior, pendiente del mes, total individual y total general; después incluye el desglose de meses y abonos. Los compañeros sin inicio figuran como **Por configurar**. No agrega una página de notas de movimientos.
- El anexo contiene nombres e información financiera individual: compártelo solo con las personas autorizadas.
- Las fotos siguen siendo opcionales. Los PDF originales adjuntos se consultan desde sus movimientos; no se intentan insertar como fotografías.

No se añaden dependencias, variables de entorno ni permisos Android. Se mantiene Supabase y el inicio de sesión actuales. No hay que volver a registrar saldos ni movimientos. La RPC de historial ya está instalada en el proyecto compartido con la web.

## Experiencia visual renovada

- **Arranque:** la app dibuja una pantalla de bienvenida mientras inicializa Supabase y las preferencias, con estado de carga y reintento ante un fallo. No se agrega una espera artificial.
- **Inicio de sesión:** fondo marfil/azul con trazos vectoriales locales, panel de acceso, logotipo original y estados de verificación. El formulario conserva sus controladores, foco, validaciones y autocompletado.
- **Consulta:** nuevo panel de período con estado «Consultando…», navegación anterior/siguiente y selector de año/mes, además de acceso al mes actual. Las listas del selector y de compañeros se desplazan incluso con teclado o texto grande.
- **Resumen:** tarjetas con respuesta al tacto/puntero y explicaciones desplegables de los fondos. Los esqueletos de carga son decorativos y no muestran cifras ficticias.
- **Movimientos y actividades:** superficies, formularios, botones y encabezados coherentes; mensaje durante el guardado; detalle de movimiento y auditoría con encabezados identificables.
- **Aportes:** conserva la deuda individual, la separación por meses y los abonos. Mejora la identificación de estados y la presentación del historial.
- **Modales:** transiciones suaves, fondo atenuado, tipografía y acciones unificadas; se mantienen los valores de confirmación, cancelación, los bloqueos durante el guardado y la protección al salir sin guardar.
- **Navegación y apariencia:** barra inferior flotante y selección animada, distribución para tablet, tema claro/oscuro/automático existente, contraste y decoración azul/dorada. La carga y las transiciones propias respetan la preferencia de reducir animaciones.
- **PDF:** incorpora el logotipo original en su encabezado y un separador azul/dorado; conserva tablas, deudas y comprobantes.

Las animaciones no guardan ni modifican registros. La decoración se dibuja localmente, sin descargas, imágenes nuevas ni dependencias adicionales.

## Validación de esta actualización

Parte de `main` en `a2cbc1b111d74ce03386fb15396b3422d515a61f`, que ya incorpora los aportes individuales. Se comprobó el parseo de los **22 archivos Dart** y la resolución de sus importaciones locales. Se compararon **18 métodos de acceso y operaciones financieras** contra la versión anterior: conservan el mismo cuerpo, normalizando únicamente el nombre del contenedor visual de los diálogos.

Se incluyen **nueve pruebas nuevas** para estados de carga, reducción de movimiento, callbacks en tarjetas, explicación de saldos, período a 320/600 px y texto grande en ambos temas, búsqueda/selección y cancelación de confirmaciones. Son pruebas preparadas, no ejecutadas en este entorno.

Pendiente ejecutar `flutter analyze`, `flutter test`, compilar Android y comprobar visualmente app y PDF. La revisión automática bloqueó anteriormente Flutter por su consulta de metadatos internos de la instancia; no se intentó eludir ese bloqueo. No se modificaron la base de datos, los permisos, las dependencias ni los datos financieros.

Comprobaciones recomendadas antes de registrar datos reales:

```bash
flutter analyze --no-fatal-infos
flutter test
```

Consulta primero un mes y compara los valores con la web. Si se usa el Supabase de producción, **confirmar un ingreso/egreso, recibir un pago, corregir fondos o cerrar meses modifica datos reales**. Para pruebas de escritura utiliza una base de pruebas con el mismo esquema, o únicamente movimientos reales verificados. No dupliques los registros históricos.

## APK desde GitHub

Actions → **Comprobar Tesorería y generar APK de prueba** → Run workflow.

El workflow manual usa Flutter 3.29.3, analiza, prueba y después compila. Si todo pasa, entrega `NA-Tesoreria-APK-prueba`, con APK y lockfile generado. No se ejecuta por cada push y no ha sido ejecutado en esta entrega.

## Conexión alternativa para pruebas

Para apuntar a otro Supabase con el mismo esquema, copia `config.example.json` a `config.local.json` y configura exclusivamente una URL y clave pública de ese proyecto.

```bash
flutter run --dart-define-from-file=config.local.json
```

`config.local.json` está excluido de git. La aplicación no recrea tablas ni migra datos.

