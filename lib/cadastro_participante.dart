
import 'package:flutter/material.dart';

class CadastroParticipante extends StatefulWidget {
  const CadastroParticipante({super.key});

  @override
  State<CadastroParticipante> createState() =>
      _CadastroParticipanteState();
}

class _CadastroParticipanteState extends State<CadastroParticipante> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final eventoController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    eventoController.dispose();
    super.dispose();
  }

  void cadastrar() {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        eventoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos!'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Participante cadastrado com sucesso!'),
      ),
    );

    nomeController.clear();
    emailController.clear();
    eventoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Participantes'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do participante',
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
              ),
            ),
            TextField(
              controller: eventoController,
              decoration: const InputDecoration(
                labelText: 'Evento',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cadastrar,
              child: const Text('Cadastrar participante'),
            ),
          ],
        ),
      ),
    );
  }
}
