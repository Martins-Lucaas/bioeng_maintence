import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:signature/signature.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CC1Page extends StatefulWidget {
  const CC1Page({super.key});

  @override
  State<CC1Page> createState() => _CC1PageState();
}

class _CC1PageState extends State<CC1Page> {
  bool isCompleted = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );
  String userName = 'Usuário desconhecido'; // Variável para armazenar o nome do usuário

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carregar o nome do usuário
    _loadCompletionStatus(); // Carregar o status de conclusão
  }

  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _databaseReference.child('colaboradores').child(user.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário desconhecido';
          });
        }
      });
    }
  }

  void _openSignaturePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assinatura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _signatureController.clear(); // Limpar assinatura
                    },
                    child: const Text('Limpar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _saveCompletionStatus();
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveCompletionStatus() async {
    if (_signatureController.isNotEmpty) {
      var signatureData = await _signatureController.toPngBytes();
      if (signatureData != null) {
        _databaseReference.child('setores/cc1').set({
          'finalizado': true,
          'assinatura': userName, // Salva o nome do colaborador
        }).then((_) {
          setState(() {
            isCompleted = true;
          });
          Navigator.of(context).pop(); // Fecha o pop-up
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assinatura está vazia!')),
      );
    }
  }

  void _loadCompletionStatus() {
    _databaseReference.child('setores/cc1').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.child('finalizado').value as bool;
          userName = event.snapshot.child('assinatura').value as String? ?? 'Usuário desconhecido';
        });
      }
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CC 1'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Finalizado'),
                Checkbox(
                  value: isCompleted,
                  onChanged: (bool? value) {
                    if (value == true) {
                      _openSignaturePopup();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isCompleted)
              Text(
                'Assinado por: $userName',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
