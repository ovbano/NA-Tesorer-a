// ignore_for_file: unused_field
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'brand.dart';
import 'group_logo.dart';
import 'supabase_config.dart';
import 'treasury.dart';
import 'workspace.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: publicSupabaseUrl);
  const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: publicSupabaseKey);
  if (url.isEmpty || !isPublicKey(key)) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Configura la URL y una clave pública de Supabase (anon o publishable). '
                'Nunca uses una clave administrativa. Sigue la guía del proyecto y '
                'ejecuta con --dart-define-from-file=config.local.json.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ));
    return;
  }
  await Supabase.initialize(url: url, anonKey: key);
  await appearance.load();
  runApp(const TreasuryApp());
}
class TreasuryApp extends StatelessWidget {
  const TreasuryApp({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appearance,
        builder: (context, _) => MaterialApp(
          title: 'Amigos Verdaderos · Tesorería',
          debugShowCheckedModeBanner: false,
          locale: const Locale('es', 'EC'),
          supportedLocales: const [Locale('es', 'EC')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: groupTheme(Brightness.light),
          darkTheme: groupTheme(Brightness.dark),
          themeMode: appearance.mode,
          themeAnimationDuration: const Duration(milliseconds: 280),
          home: const AuthGate(),
        ),
      );
}
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  late final TreasuryRepository repo;
  StreamSubscription<AuthState>? subscription;
  Future<Json>? access;
  Future<Json>? pendingAccess() {
    if (repo.client.auth.currentSession == null) return null;
    return repo.profile().timeout(const Duration(seconds: 20));
  }
  void refreshAccess() {
    if (!mounted) return;
    // Crear el Future fuera de setState evita devolverlo desde el callback.
    final Future<Json>? next = pendingAccess();
    setState(() {
      access = next;
    });
  }
  @override
  void initState() {
    super.initState();
    repo = TreasuryRepository(Supabase.instance.client);
    access = pendingAccess();
    subscription = repo.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.event == AuthChangeEvent.signedOut) {
        setState(() {
          access = null;
        });
      } else if (event.event == AuthChangeEvent.signedIn) {
        refreshAccess();
      } else if (event.event == AuthChangeEvent.initialSession && access == null) {
        // Evita duplicar la petición iniciada en initState.
        refreshAccess();
      }
    });
  }
  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (access == null) return LoginScreen(repo: repo);
    return FutureBuilder<Json>(
      future: access,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AccessStatusScreen(
            isError: true,
            description: message(snapshot.error!),
            onRetry: refreshAccess,
            onSignOut: () async {
              await repo.client.auth.signOut(scope: SignOutScope.local);
            },
          );
        }
        if (!snapshot.hasData) {
          return const _AccessStatusScreen(isError: false);
        }
        return Workspace(
          key: ValueKey(snapshot.data!['id']),
          repo: repo,
          profile: snapshot.data!,
        );
      },
    );
  }
}
// Estilos específicos de autenticación, sin afectar otras pantallas.
class _AuthColors {
  static const navy = brandNavy;
  static const gold = brandGold;
  static const pale = Color(0xFFE9EFFB);
  static const midnight = Color(0xFF091426);
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color line(BuildContext context) => dark(context)
      ? const Color(0xFF40526F)
      : const Color(0xFFD8E1EF);
  static Color faded(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}
class _AuthHeader extends StatelessWidget implements PreferredSizeWidget {
  const _AuthHeader({this.title = 'Tesorería del grupo'});
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(74);
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 350;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 74,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AuthColors.navy, Color(0xFF174384), Color(0xFF102D5D)],
          ),
          border: Border(bottom: BorderSide(color: _AuthColors.gold, width: 1.2)),
        ),
      ),
      titleSpacing: narrow ? 14 : 20,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _AuthColors.gold.withOpacity(.60)),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: _AuthColors.gold, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AMIGOS VERDADEROS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: _AuthColors.gold)),
                const SizedBox(height: 3),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 7),
          child: IconTheme(
            data: IconThemeData(color: Colors.white),
            child: ThemeButton(),
          ),
        ),
      ],
    );
  }
}
class _AuthHero extends StatelessWidget {
  const _AuthHero();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AuthColors.navy, Color(0xFF173D7A), Color(0xFF0E2A57)],
          ),
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: _AuthColors.gold.withOpacity(.65)),
          boxShadow: [
            BoxShadow(
              color: _AuthColors.navy.withOpacity(.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // El logotipo permanece exactamente como está implementado.
            const GroupLogo(
              size: 120,
              variant: GroupLogoVariant.featured,
            ),
            const SizedBox(height: 17),
            const Text('NARCÓTICOS ANÓNIMOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    color: _AuthColors.gold)),
            const SizedBox(height: 8),
            const Text('AMIGOS VERDADEROS',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    color: Colors.white)),
            const SizedBox(height: 10),
            const Text('Tesorería · Transparencia y servicio',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFFE3EAF8), height: 1.45)),
            const SizedBox(height: 19),
            Container(height: 1, color: _AuthColors.gold.withOpacity(.34)),
            const SizedBox(height: 13),
            const Text('Un día a la vez, juntos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _AuthColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      );
}
class _AuthPanel extends StatelessWidget {
  const _AuthPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 23, 21, 23),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: _AuthColors.line(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_AuthColors.dark(context) ? .12 : .045),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({required this.label, required this.onPressed, this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _AuthColors.navy,
            foregroundColor: Colors.white,
            iconColor: Colors.white,
            disabledBackgroundColor: _AuthColors.navy.withOpacity(.60),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(0, 58),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          icon: busy
              ? const SizedBox(
                  height: 19,
                  width: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.login_rounded, size: 21),
          label: Text(label),
        ),
      );
}
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.repo});
  final TreasuryRepository repo;
  @override
  State<LoginScreen> createState() => _LoginState();
}
class _LoginState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final emailFocus = FocusNode(debugLabel: 'login-email');
  final passwordFocus = FocusNode(debugLabel: 'login-password');
  final form = GlobalKey<FormState>();
  bool busy = false;
  bool visible = false;
  String? error;
  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
  Future<void> login() async {
    if (busy || !(form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repo.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) setState(() => error = message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = screenWidth < 360 ? 14.0 : 20.0;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: const _AuthHeader(),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // No cerrar el teclado al reajustar o desplazar el formulario.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: AutofillGroup(
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Se mantiene el mismo lugar en el árbol al abrir el teclado.
                      // Así no se recrean los campos ni se pierde su foco.
                      Visibility(
                        visible: !keyboardVisible,
                        maintainState: true,
                        child: const _AuthHero(),
                      ),
                      SizedBox(height: keyboardVisible ? 0 : 18),
                      _AuthPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 39,
                                  height: 39,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.lock_person_outlined,
                                      color: scheme.onPrimaryContainer, size: 21),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Acceso a Tesorería',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text('Ingresa con la misma cuenta que utilizas en la plataforma web.',
                                style: TextStyle(color: _AuthColors.faded(context), height: 1.5)),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: email,
                              focusNode: emailFocus,
                              enabled: !busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'nombre@correo.com',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) =>
                                  (value ?? '').trim().contains('@') ? null : 'Escribe un correo válido',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: password,
                              focusNode: passwordFocus,
                              enabled: !busy,
                              obscureText: !visible,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
                                  onPressed: () => setState(() => visible = !visible),
                                  icon: Icon(visible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                              onFieldSubmitted: (_) => login(),
                              validator: (value) => (value ?? '').isNotEmpty
                                  ? null
                                  : 'Escribe tu contraseña',
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: scheme.error.withOpacity(.35)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        color: scheme.onErrorContainer, size: 21),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(error!,
                                        style: TextStyle(
                                            color: scheme.onErrorContainer, height: 1.45))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _PrimaryAuthButton(
                              label: busy ? 'Verificando acceso…' : 'Iniciar sesión',
                              onPressed: busy ? null : login,
                              busy: busy,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 18, color: _AuthColors.faded(context)),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              'Acceso exclusivo para cuentas autorizadas por el grupo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: _AuthColors.faded(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text('Si necesitas acceso, solicítalo al administrador del grupo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: _AuthColors.faded(context),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _AccessStatusScreen extends StatelessWidget {
  const _AccessStatusScreen({required this.isError, this.description, this.onRetry, this.onSignOut});
  final bool isError;
  final String? description;
  final VoidCallback? onRetry;
  final VoidCallback? onSignOut;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const _AuthHeader(title: 'Verificación de acceso'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: _AuthPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isError ? scheme.errorContainer : scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: isError
                            ? Icon(Icons.gpp_maybe_outlined,
                                color: scheme.onErrorContainer, size: 40)
                            : SizedBox(
                                height: 40,
                                width: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 21),
                    Text(isError ? 'No pudimos verificar el acceso' : 'Verificando tu cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        )),
                    const SizedBox(height: 10),
                    Text(description ?? 'Estamos comprobando tu sesión y permisos en Tesorería.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _AuthColors.faded(context), height: 1.55)),
                    if (isError) ...[
                      const SizedBox(height: 23),
                      _PrimaryAuthButton(label: 'Volver a intentar', onPressed: onRetry),
                      const SizedBox(height: 7),
                      TextButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Volver al inicio de sesión'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}