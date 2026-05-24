import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/prato.dart';
import '../widgets/custom_input.dart';
import '../widgets/rating_slider.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  File? _image;
  final _picker = ImagePicker();
  bool _isSaving = false;

  void _atualizarVoltaria() {
    if (!_manualOverrideVoltaria) {
      double media = (_notaComida * 0.6) + (_notaCustoBeneficio * 0.4);
      setState(() {
        _voltaria = media >= 3.5;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToSupabase(File image) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final imageBytes = await image.readAsBytes();
      
      await Supabase.instance.client.storage
          .from('pratos_images')
          .uploadBinary(fileName, imageBytes);

      final String publicUrl = Supabase.instance.client.storage
          .from('pratos_images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Erro no upload: $e');
      return null;
    }
  }

  Future<void> _salvarPrato() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        String? imagePath;
        if (_image != null) {
          imagePath = await _uploadImageToSupabase(_image!);
          if (imagePath == null) {
            throw Exception("Falha ao fazer upload da imagem.");
          }
        }

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
          imagePath: imagePath,
        );

        final provider = context.read<AppProvider>();
        await provider.addPrato(prato);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: AppText('Avaliação salva com sucesso!', color: Colors.white),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText('Erro ao salvar: ${e.toString()}', color: Colors.white),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Preencha os campos obrigatórios.', color: Colors.white),
          backgroundColor: AppColors.danger,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: AppText.subtitle('Nova Avaliação'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              CustomInput(
                controller: _descricaoPratoController,
                label: 'Descrição do Prato (Ex: Bife Acebolado)',
                icon: Icons.fastfood,
                validator: (value) => value == null || value.isEmpty ? 'Informe o prato' : null,
              ),
              const SizedBox(height: 24),
              RatingSlider(
                label: 'Avaliação da Comida (Peso 60%)',
                value: _notaComida,
                activeColor: Colors.orange,
                onChanged: (val) {
                  setState(() {
                    _notaComida = val;
                    _atualizarVoltaria();
                  });
                },
              ),
              const SizedBox(height: 16),
              RatingSlider(
                label: 'Custo-Benefício (Peso 40%)',
                value: _notaCustoBeneficio,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    _notaCustoBeneficio = val;
                    _atualizarVoltaria();
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildMediaDisplay(mediaAtual),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const AppText('Comer de novo?', bold: true),
                subtitle: const AppText('Cálculo automático baseado na nota.', type: AppTextType.caption),
                value: _voltaria,
                activeThumbColor: AppColors.success,
                onChanged: (val) {
                  setState(() {
                    _voltaria = val;
                    _manualOverrideVoltaria = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: _observacoesController,
                label: 'Observações Adicionais (Opcional)',
                icon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Salvar Avaliação',
                  icon: Icons.save,
                  onPressed: _salvarPrato,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImageSourceActionSheet(),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: AppLayout.borderLarge,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: AppLayout.borderLarge,
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        AppText('Adicionar Foto do Prato', color: Colors.grey.shade600),
                      ],
                    ),
            ),
          ),
          if (_image != null)
            TextButton.icon(
              onPressed: () => setState(() => _image = null),
              icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
              label: const AppText('Remover Foto', color: AppColors.danger, type: AppTextType.detail),
            ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const AppText('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const AppText('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaDisplay(double mediaAtual) {
    return Container(
      padding: AppLayout.paddingM,
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: AppLayout.borderMedium,
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText('Média Calculada:', type: AppTextType.body),
          AppText.title(
            mediaAtual.toStringAsFixed(2),
            color: AppColors.info,
          ),
        ],
      ),
    );
  }
}
