import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'treasury.dart';
import 'supabase_config.dart';
import 'workspace.dart';
import 'brand.dart';
import 'group_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url=String.fromEnvironment('SUPABASE_URL',defaultValue:publicSupabaseUrl);const key=String.fromEnvironment('SUPABASE_ANON_KEY',defaultValue:publicSupabaseKey);
  if(url.isEmpty || !isPublicKey(key)){runApp(const MaterialApp(home:Scaffold(body:Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Configura la URL y una clave pública de Supabase (anon o publishable). Nunca uses una clave administrativa. Sigue la guía del proyecto y ejecuta con --dart-define-from-file=config.local.json.'))))));return;}
  await Supabase.initialize(url:url,anonKey:key);
  await appearance.load();
  runApp(const TreasuryApp());
}
class TreasuryApp extends StatelessWidget {
  const TreasuryApp({super.key});
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: appearance,
    builder: (context, _) => MaterialApp(title: 'Amigos Verdaderos · Tesorería', debugShowCheckedModeBanner: false,
      locale: const Locale('es','EC'), supportedLocales: const [Locale('es','EC')], localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: groupTheme(Brightness.light), darkTheme: groupTheme(Brightness.dark), themeMode: appearance.mode,
      themeAnimationDuration: const Duration(milliseconds: 250), home: const AuthGate()),
  );
}
class AuthGate extends StatefulWidget { const AuthGate({super.key});@override State<AuthGate> createState()=>_AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  late final TreasuryRepository repo;StreamSubscription<AuthState>? subscription;Future<Json>? access;
  Future<Json>? pendingAccess() {
    if (repo.client.auth.currentSession == null) return null;
    return repo.profile().timeout(const Duration(seconds: 20));
  }

  void refreshAccess() {
    if (!mounted) return;
    // Start the request outside setState. An expression assignment would
    // return this Future and trigger Flutter's runtime assertion.
    final next = pendingAccess();
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
      } else if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.initialSession) {
        refreshAccess();
      }
    });
  }
  @override void dispose(){subscription?.cancel();super.dispose();}
  @override Widget build(BuildContext context){if(access==null)return LoginScreen(repo:repo);return FutureBuilder<Json>(future:access,builder:(context,s){if(s.hasError)return Scaffold(appBar:AppBar(title:const Text('Acceso a Tesorería')),body:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(message(s.error!)),const SizedBox(height:20),FilledButton(onPressed:refreshAccess,child:const Text('Reintentar')),TextButton(onPressed:()async{await repo.client.auth.signOut(scope:SignOutScope.local);},child:const Text('Volver al inicio de sesión'))])));if(!s.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));return Workspace(key:ValueKey(s.data!['id']),repo:repo,profile:s.data!);});}
}
class LoginScreen extends StatefulWidget {const LoginScreen({super.key,required this.repo});final TreasuryRepository repo;@override State<LoginScreen> createState()=>_LoginState();}
class _LoginState extends State<LoginScreen> {
  final email=TextEditingController(),password=TextEditingController();final form=GlobalKey<FormState>();bool busy=false,visible=false;String? error;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> login()async{if(busy||!form.currentState!.validate())return;setState((){busy=true;error=null;});try{await widget.repo.client.auth.signInWithPassword(email:email.text.trim(),password:password.text);}catch(e){if(mounted)setState(()=>error=message(e));}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Bienvenido'),actions:const [ThemeButton()]),body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Center(child: GroupLogo(size: 120)),const SizedBox(height:20),const Text('Amigos Verdaderos',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const Text('NARCÓTICOS ANÓNIMOS\nTesorería del grupo',textAlign:TextAlign.center,style:TextStyle(height:1.7)),const SizedBox(height:12),Text('Un día a la vez, juntos.',textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.secondary,fontStyle:FontStyle.italic)),const SizedBox(height:32),TextFormField(controller:email,keyboardType:TextInputType.emailAddress,autofillHints:const [AutofillHints.username],decoration:const InputDecoration(labelText:'Correo electrónico',prefixIcon:Icon(Icons.mail_outline)),validator:(v)=>(v??'').contains('@')?null:'Escribe tu correo'),const SizedBox(height:16),TextFormField(controller:password,obscureText:!visible,autofillHints:const [AutofillHints.password],decoration:InputDecoration(labelText:'Contraseña',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(tooltip:visible?'Ocultar contraseña':'Mostrar contraseña',onPressed:()=>setState(()=>visible=!visible),icon:Icon(visible?Icons.visibility_off:Icons.visibility))),onFieldSubmitted:(_)=>login(),validator:(v)=>(v??'').isNotEmpty?null:'Escribe tu contraseña'),if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(error!,style:const TextStyle(color:Colors.red))),const SizedBox(height:24),FilledButton(onPressed:busy?null:login,child:Text(busy?'Ingresando…':'Iniciar sesión')),const SizedBox(height:18),const Text('Utiliza la misma cuenta que en la web. Si necesitas acceso, solicítalo al administrador.',textAlign:TextAlign.center)])))))));
}
