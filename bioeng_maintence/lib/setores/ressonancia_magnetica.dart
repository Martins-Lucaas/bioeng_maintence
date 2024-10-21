import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signature/signature.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RessonanciaMagneticaPage extends StatefulWidget {
  const RessonanciaMagneticaPage({super.key});

  @override
  State<RessonanciaMagneticaPage> createState() => _RessonanciaMagneticaPageState();
}

class _RessonanciaMagneticaPageState extends State<RessonanciaMagneticaPage> {
  bool isCompleted = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final SignatureController _signatureController = SignatureController(penStrokeWidth: 5, penColor: Colors.black);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  String userName = 'Usuário';
  final String _qrData = 'app://setor/ressonancia_magnetica'; // QR code fixo para deep link

  List<TableRow> tableRows = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
    _loadUserData();
    _initializeTableRows(); // Inicializa as linhas da tabela
    _listenForTableChanges(); // Adiciona o listener para monitorar mudanças na tabela
  }

  // Método para inicializar as linhas da tabela
  void _initializeTableRows() async {
    DataSnapshot snapshot = await _databaseReference.child('setores/ressonancia_magnetica/tabela').get();
    
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final rowData = value as Map;
        bool isRowCompleted = rowData['finalizado'] ?? false;
        
        setState(() {
          tableRows.add(
            tableRow('$key', rowData, isRowCompleted), // Utiliza o método tableRow para adicionar uma linha
          );
        });
      });
    }
    _addNewTableRow(); // Sempre adiciona uma nova linha editável ao final
  }

  // Adiciona o listener para detectar mudanças na tabela no Firebase
  void _listenForTableChanges() {
    _databaseReference.child('setores/ressonancia_magnetica/tabela').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        tableRows = data.entries.map((entry) {
          final index = entry.key;
          final rowData = entry.value as Map;
          bool isRowCompleted = rowData['finalizado'] ?? false;

          return tableRow('$index', rowData, isRowCompleted);
        }).toList();
      });
    });
  }

  // Adiciona uma nova linha editável ao final
  void _addNewTableRow() {
    final newIndex = tableRows.length + 1;
    setState(() {
      tableRows.add(
        tableRow('linha$newIndex', {
          'nivelHelio': '',
          'horimetro': '',
          'pressao': '',
          'temperatura': '',
          'umidade': '',
          'finalizado': false,
        }, false), // Adiciona uma nova linha editável
      );
    });

    // Salva a nova linha no Firebase
    final newRowRef = _databaseReference.child('setores/ressonancia_magnetica/tabela').child('linha$newIndex');
    newRowRef.set({
      'nivelHelio': '',
      'horimetro': '',
      'pressao': '',
      'temperatura': '',
      'umidade': '',
      'finalizado': false,
    });
  }

  void _loadUserData() {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _databaseReference.child('users/colaboradores').child(currentUser!.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        }
      });
    }
  }

  void _loadCompletionStatus() {
    _databaseReference.child('setores/ressonancia_magnetica/finalizado').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.value as bool? ?? false;
        });
      }
    });
  }

  // Função para renderizar o header da tabela
  Widget tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Função para criar células editáveis ou bloqueadas dependendo do status da linha
  Widget editableCell(String rowIndex, String fieldName, String initialValue, bool isRowCompleted) {
    final controllerKey = '$rowIndex-$fieldName';
    if (!_controllers.containsKey(controllerKey)) {
      _controllers[controllerKey] = TextEditingController(text: initialValue);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _controllers[controllerKey],
        enabled: !isRowCompleted, // Desativa a edição se a linha estiver finalizada
        onChanged: (value) {
          _saveCellData(fieldName, rowIndex, value); // Salva automaticamente ao editar
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Função para salvar os dados das células no Firebase
  void _saveCellData(String fieldName, String rowIndex, String value) {
    final cellRef = _databaseReference.child('setores/ressonancia_magnetica/tabela').child(rowIndex).child(fieldName);
    cellRef.set(value);
  }

  // Função para renderizar as linhas da tabela
  TableRow tableRow(String rowIndex, Map rowData, bool isRowCompleted) {
    return TableRow(
      children: [
        Text(rowIndex, textAlign: TextAlign.center),
        editableCell(rowIndex, 'nivelHelio', rowData['nivelHelio'] ?? '', isRowCompleted),
        editableCell(rowIndex, 'horimetro', rowData['horimetro'] ?? '', isRowCompleted),
        editableCell(rowIndex, 'pressao', rowData['pressao'] ?? '', isRowCompleted),
        editableCell(rowIndex, 'temperatura', rowData['temperatura'] ?? '', isRowCompleted),
        editableCell(rowIndex, 'umidade', rowData['umidade'] ?? '', isRowCompleted),
      ],
    );
  }

  // Exibe o QR Code em uma tela ampliada e dá a opção de salvar como PDF
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
              data: _qrData,  // Gera o QR code com a URL armazenada em _qrData
              version: QrVersions.auto,
              size: 300.0,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _saveQRCodeAsPDF();  // Função para salvar o QR code como PDF
              },
              child: const Text('Salvar como PDF'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();  // Fecha o pop-up
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Função para salvar o QR Code como PDF
  Future<void> _saveQRCodeAsPDF() async {
    final pdf = pw.Document();
    final qrImage = await QrPainter(
      data: _qrData,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(300); // Gera a imagem do QR Code

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
          );
        },
      ),
    );

    // Solicita para o usuário salvar o PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'qr_code_ressonancia_magnetica.pdf',
    );
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
                      _saveCompletionStatus(); // Salvar status de conclusão e adicionar nova linha
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

  // Função que salva os dados e adiciona uma nova linha
  void _saveCompletionStatus() async {
    if (_signatureController.isNotEmpty) {
      var signatureData = await _signatureController.toPngBytes();
      if (signatureData != null) {
        String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        // Gerando um novo índice baseado no número de linhas existentes
        final newIndex = tableRows.length;

        // Salvando os dados finalizados na linha existente
        final completionRef = _databaseReference.child('setores/ressonancia_magnetica/tabela/linha$newIndex');
        
        await completionRef.update({
          'finalizado': true,
          'assinatura': {
            'imagem': signatureData,  // Assinatura em PNG
          },
          'colaborador': userName, // Nome do colaborador
          'data_hora': dateTime, // Data e hora da assinatura
        });

        setState(() {
          isCompleted = true;
        });

        // Adicionando uma nova linha vazia após a finalização
        _addNewTableRow();

        // Fechar o pop-up de assinatura
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RESSONÂNCIA MAGNÉTICA GE SIGNA HDXT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Retornar para a página anterior
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1,5 T | ID: 11059/085222 | NS:MRR8291',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Finalizado',
                  style: TextStyle(fontSize: 16),
                ),
                Checkbox(
                  value: isCompleted,
                  onChanged: (bool? value) {
                    if (value == true && !isCompleted) {
                      _openSignaturePopup(); // Abrir o pop-up de assinatura
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tabela editável
            Table(
              border: TableBorder.all(),
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
                5: FlexColumnWidth(2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Colors.grey),
                  children: [
                    tableHeader(''),
                    tableHeader('Nível de Hélio (%)'),
                    tableHeader('Horímetro (KHr)'),
                    tableHeader('Pressão (Psi)'),
                    tableHeader('Temperatura da Sala Técnica (ºC)'),
                    tableHeader('Umidade da Sala Técnica (%)'),
                  ],
                ),
                ...tableRows, // Exibe as linhas da tabela dinamicamente
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!isCompleted) {
                  _openSignaturePopup(); // Abre o pop-up de assinatura
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
            GestureDetector(
              onTap: () {
                _showQRCodeDialog(context); // Exibe o QR Code em tela cheia
              },
              child: Center(
                child: QrImageView(
                  data: _qrData, // Gera QR Code com o deep link fixo
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
