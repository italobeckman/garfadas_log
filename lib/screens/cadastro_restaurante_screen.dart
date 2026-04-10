import 'package:flutter/material.dart';
import '../models/restaurante.dart';
import '../database/database_helper.dart';

class CadastroRestauranteScreen extends StatefulWidget {
  const CadastroRestauranteScreen({super.key});

  @override
  State<CadastroRestauranteScreen> createState() => _CadastroRestauranteScreenState();
}

class _CadastroRestauranteScreenState extends State<CadastroRestauranteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _tipoController = TextEditingController();

  Future<void> _salvarRestaurante() async {
    if (_formKey.currentState!.validate()) {
      final restaurante = Restaurante(
        nome: _nomeController.text.trim(),
        tipo: _tipoController.text.trim(),
      );

      await DatabaseHelper().insertRestaurante(restaurante);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurante salvo com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campos obrigatórios não preenchidos.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Restaurante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Estabelecimento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo (Ex: Restaurante, Padaria)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o tipo' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvarRestaurante,
                  child: const Text('Salvar Restaurante', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
