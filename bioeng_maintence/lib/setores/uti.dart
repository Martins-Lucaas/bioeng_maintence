import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:signature/signature.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UTIPage extends StatefulWidget {
  const UTIPage({super.key});

  @override
  State<UTIPage> createState() => _UTIPageState();
}

class _UTIPageState extends State<UTIPage> {
  bool isCompleted = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  String userName = 'Usuário';
  final String _qrData = 'app://setor/uti';

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
    _loadUserData();
  }

  void _loadUserData() {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _databaseReference
          .child('users/colaboradores')
          .child(currentUser!.uid)
          .once()
          .then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
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
        String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        _databaseReference.child('setores/uti').set({
          'finalizado': true,
          'assinatura': {
            'imagem': signatureData,
          },
          'colaborador': userName,
          'data_hora': dateTime,
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
    _databaseReference.child('setores/uti').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.child('finalizado').value as bool;
        });
      }
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveQRCodeAsPDF() async {
    final pdf = pw.Document();
    final qrImage = await QrPainter(
      data: _qrData,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(300);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'qr_code_uti.pdf',
    );
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 300.0,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _saveQRCodeAsPDF();
              },
              child: const Text('Salvar como PDF'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UTI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _showQRCodeDialog(context);
              },
              child: Center(
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!isCompleted) {
                  _openSignaturePopup();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('O setor já foi finalizado.'),
                    ),
                  );
                }
              },
              child: const Text('Finalizar Ronda'),
            ),
            const SizedBox(height: 20),
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
