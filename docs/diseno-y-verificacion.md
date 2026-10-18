# Diseño de Tesorería

Identidad: logo original de Amigos Verdaderos, azul marino, blanco y acentos dorados. Tema claro, oscuro y automático; se guarda la preferencia localmente.

- Resumen: disponible, fondos separados, balance del período y movimientos recientes.
- Movimientos: búsqueda, filtros, importes legibles, estado y formulario agrupado.
- Aportes: tarjetas de cuotas con lo recibido, pendiente y avance. Las actividades se muestran por separado, con deuda original, abonos históricos, pagos del sistema, comprobantes y acciones.
- Tu espacio: apariencia, guía, cierres, auditoría, fondos iniciales, cuenta y acceso al panel administrativo.
- Formularios: selectores en paneles inferiores, búsqueda por nombre o apellido que admite acentos, espacio para teclado y confirmación antes de descartar cambios.
- Períodos: selector de meses y año, accesos al mes anterior/siguiente.
- Accesibilidad: texto del sistema sin forzar su reducción, controles que envuelven textos largos, contenido desplazable y navegación lateral en pantallas amplias. En pantallas de poca altura, el período se desplaza con la lista.

## Correcciones

1. No se usa `TextTheme.apply(fontSizeFactor: ...)` sobre estilos parcialmente definidos. Se establecen los tamaños con `copyWith`, conservando los colores del tema.
2. Cada `ExpansionTile` de actividad usa una `PageStorageKey` exclusiva por ID. Su estado booleano no comparte la entrada usada por el desplazamiento de la lista, que guarda un `double`.
3. Los selectores calculan su espacio disponible al abrirse el teclado. Las imágenes que no pueden decodificarse muestran un mensaje.
4. Las fechas iniciales de los calendarios se mantienen dentro del intervalo válido.

## Comprobación local

```bash
flutter pub get
flutter test
flutter analyze
flutter run
```

`test/design_regression_test.dart` cubre construcción de ambos temas, colisión de estado de actividades, tarjetas a 320/360/600/1024 px y escalado de texto 1x/2x, y búsqueda de compañeros con acentos.

Estas pruebas requieren Flutter: se añadieron al repositorio, pero no se ejecutaron en el entorno de edición. Se revisó la sintaxis de todos los archivos Dart. La comprobación visual final se realiza en el dispositivo.

Se conserva el backend, los permisos, los datos financieros y las operaciones de ingreso, corrección y pago. Los abonos históricos no se suman otra vez al fondo general.
