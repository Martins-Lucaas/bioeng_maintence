import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedUserType; // "Colaborador" ou "Administrador"
  bool _showRegistrationForm = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  void _formatDateOfBirth(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }
    String formattedDate = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formattedDate += '/';
      }
      formattedDate += digitsOnly[i];
    }
    _dateOfBirthController.text = formattedDate;
    _dateOfBirthController.selection = TextSelection.fromPosition(
      TextPosition(offset: _dateOfBirthController.text.length),
    );
  }

  Future<void> _register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');

      if (_selectedUserType == 'Colaborador') {
        usersRef.child('colaboradores').child(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else if (_selectedUserType == 'Administrador') {
        usersRef.child('administradores').child(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar conta: $e')),
      );
    }
  }

  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
      _showRegistrationForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Selecione o tipo de usuário:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectUserType('Colaborador'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Colaborador' ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Colaborador'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _selectUserType('Administrador'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Administrador' ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Administrador'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              if (_showRegistrationForm) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                    hintText: 'dd/mm/aaaa',
                  ),
                  keyboardType: TextInputType.datetime,
                  onChanged: _formatDateOfBirth,
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Registrar'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
