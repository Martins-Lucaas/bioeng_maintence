import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Map<String, dynamic>? _userData;
  String ticket = 'Não validado'; // Variável inicializada.

  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          _databaseReference.child('users/medicos').child(user.uid);
      userRef.once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            _userData = Map<String, dynamic>.from(event.snapshot.value as Map);
            _userData!['userType'] = 'Médico';
            _counter = _userData!['counter'] ?? 0;
          });
        } else {
          userRef = _databaseReference.child('users/pacientes').child(user.uid);
          userRef.once().then((DatabaseEvent event) {
            if (event.snapshot.exists) {
              setState(() {
                _userData =
                    Map<String, dynamic>.from(event.snapshot.value as Map);
                _userData!['userType'] = 'Paciente';
                _counter = _userData!['counter'] ?? 0;
              });
            }
          });
        }
      });
    }
  }

  void _incrementCounter() {
    if (_userData != null) {
      setState(() {
        _counter++;
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String userType =
              _userData!['userType'] == 'Médico' ? 'medicos' : 'pacientes';
          _databaseReference
              .child('users')
              .child(userType)
              .child(user.uid)
              .update({
            'counter': _counter,
          });
        }
      });
    }
  }

  void readQRCode() async {
    String code = await FlutterBarcodeScanner.scanBarcode(
      "FFFFFF",
      "Cancelar",
      false,
      ScanMode.QR,
    );
    setState(() => ticket = code != '-1' ? code : 'Não validado');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              subtitle: const Text('Tela de início'),
              onTap: () {
                print('home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Finalizar sessão'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: null,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_userData != null) ...[
              Text('Nome: ${_userData!['name']}',
                  style: Theme.of(context).textTheme.bodyLarge),
              Text('E-mail: ${_userData!['email']}',
                  style: Theme.of(context).textTheme.bodyLarge),
              Text('Tipo de Usuário: ${_userData!['userType']}',
                  style: Theme.of(context).textTheme.bodyLarge),
              if (_userData!['userType'] == 'Médico')
                Text('CRM: ${_userData!['crm'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodyLarge),
              Text('Data de Nascimento: ${_userData!['dateOfBirth']}',
                  style: Theme.of(context).textTheme.bodyLarge),
            ] else ...[
              const Text('Carregando informações do usuário...'),
            ],
            const SizedBox(height: 20),
            const Text('Você pressionou o botão esta quantidade de vezes:'),
            Text('$_counter',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Text('Código do QR: $ticket',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge), // Exibe o código do QR
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: readQRCode,
        tooltip: 'QR Code',
        child: const Icon(Icons.qr_code),
      ),
    );
  }
}
