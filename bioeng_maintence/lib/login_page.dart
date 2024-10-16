import 'package:bioeng_maintence/register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';
import 'adm_main_page.dart'; // Certifique-se de importar a página do administrador

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref(); // Referência ao Firebase Realtime Database

  Future<void> _login() async {
    try {
      // Realiza o login com o email e senha fornecidos
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      User? user = _auth.currentUser;

      // Verifica se o usuário é um administrador ou colaborador
      if (user != null) {
        DatabaseEvent adminCheck = await _databaseReference.child('users/administradores').child(user.uid).once();
        
        if (adminCheck.snapshot.exists) {
          // Se o usuário for um administrador, redireciona para a página do administrador
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login de administrador realizado com sucesso!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdmMainPage()), // Redireciona para a página do administrador
          );
        } else {
          // Se não for administrador, redireciona para a página principal do colaborador
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login de colaborador realizado com sucesso!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Página Inicial')), // Redireciona para a página do colaborador
          );
        }
      }
    } catch (e) {
      // Exibe uma mensagem de erro se houver falha no login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao fazer login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fundo com a imagem
          Positioned.fill(
            child: Image.asset(
              'assets/images/ufu.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Bioengenharia UFU',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Conteúdo do login
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80), // Espaçamento adicional abaixo do título
                  Opacity(
                    opacity: 0.9, // Transparência do contêiner de login
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85, // Ajusta a largura do contêiner
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD9D9D9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo de e-mail
                          const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD9D9D9)),
                            ),
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'e-mail',
                                border: InputBorder.none,
                                icon: Icon(Icons.email),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Campo de senha
                          const Text(
                            'Senha',
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD9D9D9)),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                hintText: 'Senha',
                                border: InputBorder.none,
                                icon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Botão de login
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: _login,
                              child: const Text(
                                'Entrar',
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Criar Conta
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                                );
                              },
                              child: const Text(
                                'Criar Conta',
                                style: TextStyle(
                                  color: Colors.black,
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
