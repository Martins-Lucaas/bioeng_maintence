import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:signature/signature.dart';

class TomografoSiemensOncologiaPage extends StatefulWidget {
  const TomografoSiemensOncologiaPage({super.key});

  @override
  State<TomografoSiemensOncologiaPage> createState() => _TomografoSiemensOncologiaPageState();
}

class _TomografoSiemensOncologiaPageState extends State<TomografoSiemensOncologiaPage> {
  bool isCompleted = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

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
        _databaseReference.child('setores/tomografo_siemens_oncologia').set({
          'finalizado': true,
          'assinatura': signatureData,
        }).then((_) {
          setState(() {
            isCompleted = true;
          });
          Navigator.of(context).pop(); // Fechar o pop-up
        });
      }
    }
  }

  void _loadCompletionStatus() {
    _databaseReference.child('setores/tomografo_siemens_oncologia').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.child('finalizado').value as bool;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
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
        title: const Text('Tomógrafo Siemens Oncologia'),
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
          ],
        ),
      ),
    );
  }
}
