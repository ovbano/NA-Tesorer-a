# Organización del código Flutter

La distribución sigue las funciones del proyecto, sin introducir un nuevo gestor de estado ni cambiar el diseño, los contratos de Supabase o las operaciones financieras del commit «Arreglo manual».

| Carpeta o archivo | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Arranque: configuración pública, inicialización de Supabase y carga de la apariencia. |
| `lib/app/treasury_app.dart` | Aplicación Material, idiomas y temas. |
| `lib/core/config/` | URL y clave pública de Supabase; comprobación de claves públicas. |
| `lib/core/theme/brand.dart` | Colores, apariencia guardada y elementos de marca existentes. |
| `lib/core/models/json.dart` | Tipo `Json` y conversión de listas de respuestas. |
| `lib/core/utils/` | Dinero en centavos, fechas y mensajes de error. |
| `lib/shared/widgets/group_logo.dart` | Logo original del grupo. |
| `lib/shared/calendar/treasury_calendar.dart` | Funciones compartidas de calendario. |
| `lib/shared/dialogs/treasury_dialogs.dart` | Diálogos reutilizables. |
| `lib/features/auth/presentation/auth_gate.dart` | Sesión, acceso, pantalla de login y sus componentes privados. |
| `lib/features/treasury/data/treasury_repository.dart` | Consultas y comandos del backend. |
| `lib/features/treasury/domain/treasury_catalog.dart` | Categorías persistidas de ingresos y egresos. |
| `lib/features/treasury/presentation/screens/` | `workspace.dart`, `entry_editor.dart` y `activity_editor.dart`. |
| `lib/features/treasury/presentation/widgets/` | Componentes de registros, encabezado, navegación e interfaz del espacio de trabajo. |
| `lib/features/treasury/presentation/reports/report_pdf.dart` | Generación del informe PDF. |
| `lib/features/treasury/treasury.dart` | Exportaciones de los nombres compartidos de Tesorería; no contiene implementaciones duplicadas. |
| `test/` | Pruebas existentes, con las importaciones actualizadas. |

## Dónde colocar cambios nuevos

- Pantalla financiera nueva: `features/treasury/presentation/screens/`.
- Componente específico de Tesorería: `features/treasury/presentation/widgets/`.
- Componente usado por varias funciones de la app: `shared/`.
- Consulta financiera nueva: `features/treasury/data/`.
- Cálculo o formato reutilizable: `core/utils/`.
- Configuración o colores: `core/config/` o `core/theme/`.

Las importaciones internas usan `package:na_tesoreria/...` para que mover una pantalla no dependa del número de carpetas que hay que subir con `../`. Los componentes privados de autenticación permanecen juntos: en Dart los identificadores con `_` son privados a su biblioteca, por lo que separarlos indiscriminadamente rompería sus referencias.

## Qué se conserva

Se conserva el contenido de las clases, funciones, validaciones, consultas, payloads RPC y componentes visuales de tu commit. No se modificaron dependencias, credenciales, Android, usuarios ni información financiera. `main.dart` continúa siendo el punto de entrada de `flutter run`.

## Verificación

Se verificó la sintaxis de los 26 archivos Dart resultantes y la resolución de 54 importaciones/exportaciones internas. Las 134 declaraciones de nivel superior, clases y cuerpos de funciones de los archivos originales se compararon con los reorganizados y permanecen idénticos.

Flutter no se ejecutó en el entorno de edición. En tu computadora:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```
