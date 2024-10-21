import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Biblioteca para formatação de datas

// Página de registro de usuário
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores para os campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instância do FirebaseAuth para autenticação

  String? _selectedUserType; // Armazena o tipo de usuário selecionado ("Colaborador" ou "Administrador")
  bool _showRegistrationForm = false; // Controla se o formulário de registro deve ser exibido

  // Função para selecionar a data de nascimento usando um date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), // Data mínima permitida
      lastDate: DateTime.now(), // Data máxima permitida
    );
    if (pickedDate != null) {
      setState(() {
        // Formata e insere a data de nascimento no campo de texto
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  // Função para formatar a data de nascimento à medida que o usuário digita
  void _formatDateOfBirth(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), ''); // Remove tudo que não for dígito
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8); // Limita a data a 8 dígitos
    }
    String formattedDate = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formattedDate += '/'; // Adiciona barras para separar dia/mês/ano
      }
      formattedDate += digitsOnly[i];
    }
    _dateOfBirthController.text = formattedDate; // Atualiza o campo de texto
    _dateOfBirthController.selection = TextSelection.fromPosition(
      TextPosition(offset: _dateOfBirthController.text.length), // Mantém o cursor no final do texto
    );
  }

  // Função para registrar o usuário no Firebase
  Future<void> _register() async {
    try {
      // Cria um novo usuário com e-mail e senha no Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Referência ao banco de dados Firebase para armazenar informações adicionais do usuário
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');

      // Verifica o tipo de usuário e salva os dados no caminho correto
      if (_selectedUserType == 'Colaborador') {
        usersRef.child('colaboradores').child(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(), // Armazena a data de criação da conta
        });
      } else if (_selectedUserType == 'Administrador') {
        usersRef.child('administradores').child(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dateOfBirth': _dateOfBirthController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Exibe uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      Navigator.pop(context); // Retorna à página anterior após o registro
    } catch (e) {
      // Exibe uma mensagem de erro se a criação falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar conta: $e')),
      );
    }
  }

  // Função para selecionar o tipo de usuário (Colaborador ou Administrador)
  void _selectUserType(String userType) {
    setState(() {
      _selectedUserType = userType; // Atualiza o tipo de usuário selecionado
      _showRegistrationForm = true; // Exibe o formulário de registro
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Conta'), // Título do AppBar
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
                  // Botão para selecionar "Colaborador"
                  ElevatedButton(
                    onPressed: () => _selectUserType('Colaborador'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedUserType == 'Colaborador' ? Colors.green : Colors.grey, // Cor muda ao selecionar
                    ),
                    child: const Text('Colaborador'),
                  ),
                  const SizedBox(width: 20),
                  // Botão para selecionar "Administrador"
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

              // Exibe o formulário de registro se um tipo de usuário for selecionado
              if (_showRegistrationForm) ...[
                TextField(
                  controller: _nameController, // Campo para inserir o nome completo
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController, // Campo para inserir o e-mail
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController, // Campo para inserir a senha
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true, // Oculta a senha durante a digitação
                ),
                const SizedBox(height: 10),

                // Campo para inserir a data de nascimento com um seletor de data
                TextField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context), // Abre o date picker ao clicar no ícone
                    ),
                    hintText: 'dd/mm/aaaa',
                  ),
                  keyboardType: TextInputType.datetime, // Define o teclado para inserção de datas
                  onChanged: _formatDateOfBirth, // Formata a data conforme o usuário digita
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register, // Executa a função de registro ao clicar no botão
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
