import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Para formatar a data

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
  final _crmController = TextEditingController(); // Controlador para o campo CRM
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedUserType; // Armazena o tipo de usuário selecionado.
  bool _showRegistrationForm = false; // Controla se o formulário de registro deve ser exibido.

  // Método para abrir o calendário e selecionar a data.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), // Data mínima.
      lastDate: DateTime.now(),  // Data máxima até hoje.
    );
    if (pickedDate != null) {
      setState(() {
        // Formata a data e coloca no campo de texto.
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  // Função para adicionar as barras (/) automaticamente durante a digitação.
  void _formatDateOfBirth(String value) {
    // Remove todos os caracteres que não são dígitos.
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Define o máximo de 8 dígitos (ddmmyyyy).
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    // Adiciona as barras conforme o formato dd/mm/aaaa.
    String formattedDate = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formattedDate += '/';
      }
      formattedDate += digitsOnly[i];
    }

    // Atualiza o valor no controlador do campo de data.
    _dateOfBirthController.text = formattedDate;

    // Movimenta o cursor para o final do campo.
    _dateOfBirthController.selection = TextSelection.fromPosition(
      TextPosition(offset: _dateOfBirthController.text.length),
    );
  }

  Future<void> _register() async {
    try {
      // Validação do CRM apenas se o usuário for do tipo "Médico".
      if (_selectedUserType == 'Médico') {
        String crm = _crmController.text.trim();
        RegExp crmRegex = RegExp(r'^CRM/[A-Z]{2} \d{6}$');
        if (!crmRegex.hasMatch(crm)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CRM inválido. Deve ser no formato: CRM/UF 123456')),
          );
          return;
        }
      }

      // Cria o usuário no Firebase Authentication.
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Referência ao banco de dados Firebase.
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');

      // Cria a estrutura no banco de dados com base no tipo de usuário selecionado.
      if (_selectedUserType == 'Médico') {
        usersRef.child('medicos').child(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'crm': _crmController.text.trim(), // Adiciona o CRM ao registro do médico.
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else if (_selectedUserType == 'Paciente') {
        usersRef.child('pacientes').child(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Mostra uma mensagem de sucesso.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      // Volta para a tela de login após o registro.
      Navigator.pop(context);
    } catch (e) {
      // Mostra uma mensagem de erro caso o registro falhe.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar conta: $e')),
      );
    }
  }

  // Método para selecionar o tipo de usuário e exibir o formulário.
  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType;
      _showRegistrationForm = true; // Exibe o formulário após a seleção.
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
              // Seção de seleção do tipo de usuário.
              const Text(
                'Selecione o tipo de usuário:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectUserType('Médico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Médico' ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Médico'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _selectUserType('Paciente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Paciente' ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Paciente'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Exibir o formulário de registro apenas após a seleção do tipo de usuário.
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

                // Campo de data de nascimento com formatação automática e calendário.
                TextField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context), // Abre o calendário.
                    ),
                    hintText: 'dd/mm/aaaa',
                  ),
                  keyboardType: TextInputType.datetime, // Permite digitar a data.
                  onChanged: _formatDateOfBirth, // Formata a data enquanto o usuário digita.
                ),

                // Campo de CRM que aparece apenas se o tipo de usuário for "Médico".
                if (_selectedUserType == 'Médico') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _crmController,
                    decoration: const InputDecoration(labelText: 'CRM'),
                  ),
                ],

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
