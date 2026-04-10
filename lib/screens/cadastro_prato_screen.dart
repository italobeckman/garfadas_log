import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prato.dart';
import '../database/database_helper.dart';

class CadastroPratoScreen extends StatefulWidget {
  final int restauranteId;

  const CadastroPratoScreen({super.key, required this.restauranteId});

  @override
  State<CadastroPratoScreen> createState() => _CadastroPratoScreenState();
}

class _CadastroPratoScreenState extends State<CadastroPratoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descricaoPratoController = TextEditingController();
  final _observacoesController = TextEditingController();

  double _notaComida = 3.0;
  double _notaCustoBeneficio = 3.0;
  bool _voltaria = true;
  bool _manualOverrideVoltaria = false;

  void _atualizarVoltaria() {
    if (!_manualOverrideVoltaria) {
      double media = (_notaComida * 0.6) + (_notaCustoBeneficio * 0.4);
      setState(() {
        _voltaria = media >= 3.5;
      });
    }
  }

  Future<void> _salvarPrato() async {
    if (_formKey.currentState!.validate()) {
      final prato = Prato(
        restauranteId: widget.restauranteId,
        descricaoPrato: _descricaoPratoController.text.trim(),
        data: DateFormat('dd/MM/yyyy').format(DateTime.now()),
        notaComida: _notaComida,
        notaCustoBeneficio: _notaCustoBeneficio,
        voltaria: _voltaria,
        observacoes: _observacoesController.text.trim().isNotEmpty
            ? _observacoesController.text.trim()
            : null,
      );

      await DatabaseHelper().insertPrato(prato);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha os campos obrigatórios.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _descricaoPratoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double mediaAtual = (_notaComida * 0.6) + (_notaCustoBeneficio * 0.4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Avaliação de Prato'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descricaoPratoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Prato (Ex: Bife Acebolado)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o prato' : null,
              ),
              const SizedBox(height: 24),
              const Text('Avaliação da Comida (Peso 60%)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Slider(
                value: _notaComida,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: _notaComida.toStringAsFixed(1),
                activeColor: Colors.orange,
                onChanged: (val) {
                  setState(() {
                    _notaComida = val;
                    _atualizarVoltaria();
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Custo-Benefício (Peso 40%)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Slider(
                value: _notaCustoBeneficio,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: _notaCustoBeneficio.toStringAsFixed(1),
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    _notaCustoBeneficio = val;
                    _atualizarVoltaria();
                  });
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Média Calculada:', style: TextStyle(fontSize: 16)),
                    Text(
                      mediaAtual.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Comer de novo? (Voltaria)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Calculadora automática. Desative para mudar manualmente.'),
                value: _voltaria,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    _voltaria = val;
                    _manualOverrideVoltaria = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações Adicionais (Opcional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _salvarPrato,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Avaliação', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
