# NA · Tesorería de Amigos Verdaderos

Aplicación Flutter / Dart independiente de la web. Esta integración conserva el nombre `na_tesoreria`, la estructura Android y el applicationId del proyecto que ya se probó en un teléfono.

## Ejecutar tu copia actual desde Git Bash

Abre **Git Bash Here** dentro de la carpeta del proyecto, la que contiene `pubspec.yaml` y `.git`.

```bash
git status --short
git fetch origin
git switch main
git pull --ff-only origin main
flutter pub get
flutter run
```

Si tienes cambios locales, guárdalos en un commit antes del pull. No uses `git reset --hard` ni borres tu carpeta para actualizar. Si hay varios dispositivos, elige el Android físico o usa `flutter run -d ID_DEL_TELEFONO` con el ID que muestra `flutter devices`.

No necesitas crear nuevamente el proyecto, ejecutar scripts Python ni ingresar otra vez los saldos. El código trae la URL y **clave pública** que ya utiliza la web en `lib/core/config/supabase_config.dart`. El usuario entra con sus credenciales actuales; las tablas, fotos y movimientos son los mismos de Supabase.

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
- Aportes por mes, pendientes de actividades, crear/corregir deuda y recibir pagos. Los pagos se incorporan una sola vez al fondo general mediante la RPC de actividades.
- Cerrar el mes contrastando dinero contado con calculado; reabrir con motivo mediante la misma operación de la web.
- PDF con ingresos y egresos separados, resumen por fondos, aportes individuales y fotografías opcionales. Se descarga evidencia secuencialmente y se limita la memoria destinada a las fotos. Si alguna falla, el PDF indica consultar el original.
- Últimos 50 eventos de auditoría y acceso al panel web del administrador.

Todavía se utiliza la web para crear/desactivar usuarios, administrar todas las participaciones de los compañeros y consultar la auditoría completa. Ese panel mantiene su propio inicio de sesión en el navegador. No hay funcionamiento offline: los borradores y las fotos se guardan en Supabase con conexión. Logo/icono definitivo pendientes.

## Validación

Se comprobó el parseo de los ocho archivos Dart, las configuraciones YAML/JSON y el manifiesto Android. Se verificaron los contratos de las RPC contra el código del sistema web. Se incluyen tests de importes en centavos, límites, clave pública, períodos y generación de PDF; la prueba del contador de Flutter fue reemplazada.

No se han ejecutado `flutter analyze`, `flutter test` ni una compilación Android en este entorno. La revisión automática bloqueó la ejecución de Flutter al intentar consultar metadatos internos de la instancia. No se intentó eludir ese bloqueo. La compilación y verificación visual deben realizarse en tu computadora o ejecutando manualmente el workflow de Actions. No se realizaron escrituras ni cambios de esquema en Supabase.

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

## Organización del código

`lib/main.dart` conserva el arranque. `app/` configura la aplicación; `core/` agrupa configuración, tema y utilidades; `shared/` reúne logo, calendarios y diálogos; `features/auth/` contiene el acceso, y `features/treasury/` organiza datos, categorías, pantallas, componentes e informes.

Consulta [la estructura y guía de ubicación de archivos](docs/estructura-del-proyecto.md). La reorganización parte del commit «Arreglo manual», conserva sus implementaciones y actualiza también las importaciones de las pruebas. Se verificaron las declaraciones, la sintaxis y las rutas; Flutter debe comprobarse en tu computadora.
