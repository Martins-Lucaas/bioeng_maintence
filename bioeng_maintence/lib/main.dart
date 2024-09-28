<<<<<<< HEAD
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
=======
import 'package:flutter/material.dart';

void main() {
>>>>>>> parent of 55674c1 (configuração banco de dados)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
<<<<<<< HEAD
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
=======
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
>>>>>>> parent of 55674c1 (configuração banco de dados)
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
<<<<<<< HEAD
=======

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

>>>>>>> parent of 55674c1 (configuração banco de dados)
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
<<<<<<< HEAD
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
=======

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
>>>>>>> parent of 55674c1 (configuração banco de dados)
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
<<<<<<< HEAD
        title: Text(widget.title),
        leading: null,
=======
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
>>>>>>> parent of 55674c1 (configuração banco de dados)
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
<<<<<<< HEAD
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
=======
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
>>>>>>> parent of 55674c1 (configuração banco de dados)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
<<<<<<< HEAD
        onPressed: readQRCode,
        tooltip: 'QR Code',
        child: const Icon(Icons.qr_code),
      ),
=======
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
>>>>>>> parent of 55674c1 (configuração banco de dados)
    );
  }
}
