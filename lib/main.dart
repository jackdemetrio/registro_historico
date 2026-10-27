
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro Histórico',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const TelaPrincipal(),
    );
  }
}

class Participante {
  final String nome;
  final String email;
  bool checkIn;

  Participante({
    required this.nome,
    required this.email,
    this.checkIn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'checkIn': checkIn,
    };
  }

  factory Participante.fromJson(Map<String, dynamic> json) {
    return Participante(
      nome: json['nome'] as String,
      email: json['email'] as String,
      checkIn: json['checkIn'] == true,
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();

  final List<Participante> participantes = [];

  Participante? ingressoAtual;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarParticipantes();
  }

  Future<void> carregarParticipantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dados = prefs.getString('participantes');

      if (dados != null) {
        final lista = jsonDecode(dados) as List<dynamic>;

        if (!mounted) return;

        setState(() {
          participantes.clear();
          participantes.addAll(
            lista.map(
                  (item) => Participante.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        mostrarMensagem('Erro ao carregar participantes.');
      }
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<bool> salvarParticipantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dados = jsonEncode(
        participantes.map((p) => p.toJson()).toList(),
      );

      return await prefs.setString('participantes', dados);
    } catch (e) {
      return false;
    }
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> gerarIngresso() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();

    if (nome.isEmpty || email.isEmpty) {
      mostrarMensagem('Preencha o nome e o e-mail.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      mostrarMensagem('Digite um e-mail válido.');
      return;
    }

    final participante = Participante(
      nome: nome,
      email: email,
    );

    setState(() {
      participantes.add(participante);
      ingressoAtual = participante;
    });

    final salvou = await salvarParticipantes();

    if (!mounted) return;

    mostrarMensagem(
      salvou
          ? 'Ingresso gerado e participante salvo!'
          : 'Ingresso gerado, mas houve erro ao salvar.',
    );
  }

  Future<void> confirmarCheckIn(Participante participante) async {
    setState(() {
      participante.checkIn = true;
    });

    final salvou = await salvarParticipantes();

    if (!mounted) return;

    mostrarMensagem(
      salvou
          ? 'Check-in realizado com sucesso!'
          : 'Check-in realizado, mas houve erro ao salvar.',
    );
  }

  Future<void> lerQrCode() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const TelaLeitorQr()),
    );

    if (!mounted || codigo == null) return;

    final linhas = codigo.split('\n');
    if (!linhas.contains('Evento: Luan Santana')) {
      mostrarMensagem('QR Code não pertence a este evento.');
      return;
    }

    String? nome;
    String? email;
    for (final linha in linhas) {
      if (linha.startsWith('Nome: ')) nome = linha.substring(6).trim();
      if (linha.startsWith('Email: ')) email = linha.substring(7).trim();
    }

    if (nome == null || email == null) {
      mostrarMensagem('QR Code inválido.');
      return;
    }

    Participante? encontrado;
    for (final participante in participantes) {
      if (participante.nome == nome && participante.email == email) {
        encontrado = participante;
        break;
      }
    }

    if (encontrado == null) {
      mostrarMensagem('Participante não encontrado.');
      return;
    }

    if (encontrado.checkIn) {
      mostrarMensagem('Este ingresso já foi utilizado.');
      return;
    }

    await confirmarCheckIn(encontrado);
  }

  Future<void> mostrarParticipantes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaParticipantes(
          participantes: participantes,
          salvarParticipantes: salvarParticipantes,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Histórico'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.music_note,
              size: 70,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 10),
            const Text(
              'Luan Santana',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Registro Histórico - Check-in',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do participante',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: gerarIngresso,
              child: const Text('Gerar ingresso'),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: mostrarParticipantes,
              icon: const Icon(Icons.people),
              label: const Text('Ver participantes'),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: lerQrCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Ler QR Code'),
            ),

            const SizedBox(height: 15),

            Text(
              'Participantes cadastrados: ${participantes.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            if (ingressoAtual != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'INGRESSO DIGITAL',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Luan Santana',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Participante: ${ingressoAtual!.nome}',
                      ),
                      Text(
                        'E-mail: ${ingressoAtual!.email}',
                      ),

                      const SizedBox(height: 20),

                      QrImageView(
                        data:
                        'Evento: Luan Santana\n'
                            'Nome: ${ingressoAtual!.nome}\n'
                            'Email: ${ingressoAtual!.email}',
                        version: QrVersions.auto,
                        size: 200,
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        'Apresente este QR Code na entrada.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      if (!ingressoAtual!.checkIn)
                        ElevatedButton.icon(
                          onPressed: () {
                            confirmarCheckIn(ingressoAtual!);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmar check-in'),
                        )
                      else
                        const Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check-in realizado com sucesso!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TelaParticipantes extends StatefulWidget {
  final List<Participante> participantes;
  final Future<bool> Function() salvarParticipantes;

  const TelaParticipantes({
    super.key,
    required this.participantes,
    required this.salvarParticipantes,
  });

  @override
  State<TelaParticipantes> createState() =>
      _TelaParticipantesState();
}

class _TelaParticipantesState extends State<TelaParticipantes> {
  Future<void> confirmarCheckIn(Participante participante) async {
    setState(() {
      participante.checkIn = true;
    });

    final salvou = await widget.salvarParticipantes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          salvou
              ? 'Check-in realizado com sucesso!'
              : 'Check-in realizado, mas houve erro ao salvar.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participantes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: widget.participantes.isEmpty
          ? const Center(
        child: Text('Nenhum participante cadastrado.'),
      )
          : ListView.builder(
        itemCount: widget.participantes.length,
        itemBuilder: (context, index) {
          final participante = widget.participantes[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.deepPurple,
              ),
              title: Text(participante.nome),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(participante.email),
                  Text(
                    participante.checkIn
                        ? 'Check-in realizado'
                        : 'Check-in pendente',
                    style: TextStyle(
                      color: participante.checkIn
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              trailing: participante.checkIn
                  ? const Icon(
                Icons.check_circle,
                color: Colors.green,
              )
                  : IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                ),
                tooltip: 'Confirmar check-in',
                onPressed: () {
                  confirmarCheckIn(participante);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}


class TelaLeitorQr extends StatefulWidget {
  const TelaLeitorQr({super.key});

  @override
  State<TelaLeitorQr> createState() => _TelaLeitorQrState();
}

class _TelaLeitorQrState extends State<TelaLeitorQr> {
  bool lendo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (lendo || capture.barcodes.isEmpty) return;
          final codigo = capture.barcodes.first.rawValue;
          if (codigo == null || codigo.isEmpty) return;
          lendo = true;
          Navigator.pop(context, codigo);
        },
      ),
    );
  }
}

