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
  @override Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Amigos Verdaderos',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:20)),actions:const [ThemeButton()]),
    body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:AutofillGroup(child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Center(child:GroupLogo(size:112)),const SizedBox(height:20),
      const Text('Tesorería del grupo',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.w700,height:1.3)),const SizedBox(height:8),
      Text('NARCÓTICOS ANÓNIMOS',textAlign:TextAlign.center,style:TextStyle(fontSize:12,letterSpacing:2,color:Theme.of(context).colorScheme.secondary,fontWeight:FontWeight.w700)),
      const SizedBox(height:8),const Text('Un día a la vez, juntos.',textAlign:TextAlign.center,style:TextStyle(height:1.5)),const SizedBox(height:28),
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(26),border:Border.all(color:Theme.of(context).colorScheme.outline.withOpacity(.18))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('Bienvenido a tu espacio',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Ingresa con la misma cuenta que utilizas en la web.',style:TextStyle(height:1.5)),const SizedBox(height:22),
        TextFormField(controller:email,keyboardType:TextInputType.emailAddress,textInputAction:TextInputAction.next,autofillHints:const [AutofillHints.username],decoration:const InputDecoration(labelText:'Correo electrónico',prefixIcon:Icon(Icons.mail_outline)),validator:(value)=>(value??'').contains('@')?null:'Escribe tu correo'),const SizedBox(height:16),
        TextFormField(controller:password,obscureText:!visible,autofillHints:const [AutofillHints.password],decoration:InputDecoration(labelText:'Contraseña',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(tooltip:visible?'Ocultar contraseña':'Mostrar contraseña',onPressed:()=>setState(()=>visible=!visible),icon:Icon(visible?Icons.visibility_off:Icons.visibility))),onFieldSubmitted:(_)=>login(),validator:(value)=>(value??'').isNotEmpty?null:'Escribe tu contraseña'),
        if(error!=null)Padding(padding:const EdgeInsets.only(top:16),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error,height:1.5))),const SizedBox(height:24),
        FilledButton.icon(onPressed:busy?null:login,icon:Icon(busy?Icons.hourglass_top:Icons.login),label:Text(busy?'Ingresando…':'Iniciar sesión')),
      ])),
      const SizedBox(height:22),Text('Si necesitas acceso, solicítalo al administrador del grupo.',textAlign:TextAlign.center,style:TextStyle(fontSize:13,height:1.5,color:Theme.of(context).colorScheme.onSurfaceVariant)),const SizedBox(height:16),
    ]))))))),
  );
}
