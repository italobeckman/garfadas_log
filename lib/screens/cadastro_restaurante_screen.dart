import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../models/restaurante.dart';
import '../widgets/custom_input.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_text.dart';
import '../widgets/app_layout.dart';
import '../services/location_service.dart';

class CadastroRestauranteScreen extends StatefulWidget {
  const CadastroRestauranteScreen({super.key});

  @override
  State<CadastroRestauranteScreen> createState() => _CadastroRestauranteScreenState();
}

class _CadastroRestauranteScreenState extends State<CadastroRestauranteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();
  TextEditingController? _nomeController;
  final LocationService _locationService = LocationService();
  
  String? _userCity;
  String? _userState;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userCity = prefs.getString('userCity');
      _userState = prefs.getString('userState');
    });
  }

  Future<void> _showLocationDialog() async {
    final cityController = TextEditingController(text: _userCity);
    final stateController = TextEditingController(text: _userState);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: AppText.subtitle('Definir Localização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomInput(controller: cityController, label: 'Cidade (ex: São Paulo)', icon: Icons.location_city),
            const SizedBox(height: 16),
            CustomInput(controller: stateController, label: 'Estado (ex: SP)', icon: Icons.map),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const AppText('Cancelar', color: AppColors.textSecondary)
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userCity', cityController.text.trim());
              await prefs.setString('userState', stateController.text.trim());
              setState(() {
                _userCity = cityController.text.trim();
                _userState = stateController.text.trim();
              });
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const AppText('Salvar', type: AppTextType.button),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarRestaurante() async {
    if (_formKey.currentState!.validate()) {
      final nome = _nomeController?.text.trim() ?? '';
      if (nome.isEmpty) return;

      final restaurante = Restaurante(
        nome: nome,
        tipo: _tipoController.text.trim(),
      );

      final provider = context.read<AppProvider>();
      await provider.addRestaurante(restaurante);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Restaurante salvo com sucesso!', color: Colors.white),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Campos obrigatórios não preenchidos.', color: Colors.white),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: AppText.subtitle('Novo Restaurante'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  final text = textEditingValue.text.trim();
                  if (text.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }

                  // Debounce para evitar bloqueio por excesso de chamadas na API (Rate Limit)
                  await Future.delayed(const Duration(milliseconds: 600));
                  if (text != _nomeController?.text.trim()) {
                    // O usuário continuou digitando, então ignoramos essa chamada
                    return const Iterable<Map<String, dynamic>>.empty();
                  }

                  return await _locationService.searchPlaces(
                    text,
                    city: _userCity,
                    state: _userState,
                  );
                },
                displayStringForOption: (option) {
                  final name = option['name']?.toString();
                  if (name != null && name.isNotEmpty) return name;
                  return option['display_name']?.toString().split(',').first ?? '';
                },
                onSelected: (Map<String, dynamic> selection) {
                  if (_tipoController.text.isEmpty && selection['type'] != null) {
                    final type = selection['type'].toString();
                    if (type == 'restaurant') _tipoController.text = 'Restaurante';
                    else if (type == 'fast_food') _tipoController.text = 'Fast Food';
                    else if (type == 'cafe') _tipoController.text = 'Café';
                    else if (type == 'bar') _tipoController.text = 'Bar';
                    else if (type == 'bakery') _tipoController.text = 'Padaria';
                  }
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  _nomeController = textEditingController;
                  return CustomInput(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                    label: 'Nome do Estabelecimento',
                    icon: Icons.store,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: AppLayout.borderMedium,
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 250,
                          maxWidth: MediaQuery.of(context).size.width - 32,
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            final title = option['name']?.toString() ?? option['display_name']?.toString().split(',').first ?? '';
                            final subtitle = option['display_name']?.toString() ?? '';
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: AppColors.primary),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppText(
                    'Buscando em: ${_userCity?.isNotEmpty == true ? _userCity : 'Qualquer lugar'}${_userState?.isNotEmpty == true ? ' - $_userState' : ''}',
                    type: AppTextType.caption,
                  ),
                  TextButton(
                    onPressed: _showLocationDialog,
                    child: const AppText('Alterar', type: AppTextType.caption, color: AppColors.primary, bold: true),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CustomInput(
                controller: _tipoController,
                label: 'Tipo (Ex: Restaurante, Padaria)',
                icon: Icons.category,
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe o tipo' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Salvar Restaurante',
                  icon: Icons.save,
                  onPressed: _salvarRestaurante,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
