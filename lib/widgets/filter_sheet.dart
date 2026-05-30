import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/restaurante.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text.dart';

// ─── Filtro de Restaurantes ───────────────────────────────────────────────────

class RestauranteFilterSheet extends StatefulWidget {
  const RestauranteFilterSheet({super.key});

  @override
  State<RestauranteFilterSheet> createState() => _RestauranteFilterSheetState();
}

class _RestauranteFilterSheetState extends State<RestauranteFilterSheet> {
  late TextEditingController _searchCtrl;
  String? _tipo;
  bool? _voltaria;
  late double _notaMinima;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _searchCtrl = TextEditingController(text: p.searchRestaurante);
    _tipo = p.tipoFilter;
    _voltaria = p.voltariaRestauranteFilter;
    _notaMinima = p.notaMinimaRestaurante;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _aplicar() {
    final provider = context.read<AppProvider>();
    provider.setFiltrosRestaurante(
      search: _searchCtrl.text,
      tipo: _tipo,
      clearTipo: _tipo == null,
      voltaria: _voltaria,
      clearVoltaria: _voltaria == null,
      notaMinima: _notaMinima,
    );
    Navigator.pop(context);
  }

  void _limpar() {
    context.read<AppProvider>().limparFiltrosRestaurante();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tipos = context.read<AppProvider>().tiposDeRestaurante;

    return _FilterSheetScaffold(
      titulo: 'Filtrar Restaurantes',
      onAplicar: _aplicar,
      onLimpar: _limpar,
      children: [
        // ── Busca por nome ──
        _FilterSection(
          label: 'Buscar por nome',
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Ex: Outback...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                  borderRadius: AppLayout.borderMedium,
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppLayout.borderMedium,
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),

        // ── Voltaria ──
        _FilterSection(
          label: 'Voltaria?',
          child: _VoltariaChips(
            value: _voltaria,
            onChanged: (v) => setState(() => _voltaria = v),
          ),
        ),

        // ── Tipo de culinária ──
        if (tipos.isNotEmpty)
          _FilterSection(
            label: 'Tipo de culinária',
            child: _TipoDropdown(
              tipos: tipos,
              value: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
          ),

        // ── Nota mínima ──
        _FilterSection(
          label: 'Nota mínima: ${_notaMinima > 0 ? _notaMinima.toStringAsFixed(1) : "Qualquer"}',
          child: Slider(
            value: _notaMinima,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.primary,
            label: _notaMinima > 0 ? _notaMinima.toStringAsFixed(1) : 'Qualquer',
            onChanged: (v) => setState(() => _notaMinima = v),
          ),
        ),
      ],
    );
  }
}

// ─── Filtro de Pratos ─────────────────────────────────────────────────────────

class PratoFilterSheet extends StatefulWidget {
  const PratoFilterSheet({super.key});

  @override
  State<PratoFilterSheet> createState() => _PratoFilterSheetState();
}

class _PratoFilterSheetState extends State<PratoFilterSheet> {
  late TextEditingController _searchCtrl;
  int? _restauranteId;
  bool? _voltaria;
  late double _notaMinima;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _searchCtrl = TextEditingController(text: p.searchPrato);
    _restauranteId = p.restauranteIdFilter;
    _voltaria = p.voltariaPratoFilter;
    _notaMinima = p.notaMinimaPrato;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _aplicar() {
    final provider = context.read<AppProvider>();
    provider.setFiltrosPrato(
      search: _searchCtrl.text,
      restauranteId: _restauranteId,
      clearRestaurante: _restauranteId == null,
      voltaria: _voltaria,
      clearVoltaria: _voltaria == null,
      notaMinima: _notaMinima,
    );
    Navigator.pop(context);
  }

  void _limpar() {
    context.read<AppProvider>().limparFiltrosPrato();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final restaurantes = context.read<AppProvider>().restaurantes;

    return _FilterSheetScaffold(
      titulo: 'Filtrar Avaliações',
      onAplicar: _aplicar,
      onLimpar: _limpar,
      children: [
        // ── Busca por descrição ──
        _FilterSection(
          label: 'Buscar por prato',
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Ex: Bife Acebolado...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                  borderRadius: AppLayout.borderMedium,
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppLayout.borderMedium,
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),

        // ── Voltaria ──
        _FilterSection(
          label: 'Comeria de novo?',
          child: _VoltariaChips(
            value: _voltaria,
            onChanged: (v) => setState(() => _voltaria = v),
          ),
        ),

        // ── Restaurante ──
        if (restaurantes.isNotEmpty)
          _FilterSection(
            label: 'Restaurante',
            child: _RestauranteDropdown(
              restaurantes: restaurantes,
              value: _restauranteId,
              onChanged: (id) => setState(() => _restauranteId = id),
            ),
          ),

        // ── Nota mínima ──
        _FilterSection(
          label: 'Média mínima: ${_notaMinima > 0 ? _notaMinima.toStringAsFixed(1) : "Qualquer"}',
          child: Slider(
            value: _notaMinima,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.primary,
            label: _notaMinima > 0 ? _notaMinima.toStringAsFixed(1) : 'Qualquer',
            onChanged: (v) => setState(() => _notaMinima = v),
          ),
        ),
      ],
    );
  }
}

// ─── Componentes internos reutilizáveis ───────────────────────────────────────

/// Scaffold comum dos dois bottom sheets de filtro.
class _FilterSheetScaffold extends StatelessWidget {
  final String titulo;
  final VoidCallback onAplicar;
  final VoidCallback onLimpar;
  final List<Widget> children;

  const _FilterSheetScaffold({
    required this.titulo,
    required this.onAplicar,
    required this.onLimpar,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alça do sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subtitle(titulo, color: AppColors.textPrimary),
                TextButton.icon(
                  onPressed: onLimpar,
                  icon: const Icon(Icons.clear_all,
                      color: AppColors.danger, size: 18),
                  label: const AppText('Limpar',
                      color: AppColors.danger, type: AppTextType.detail),
                ),
              ],
            ),
            const Divider(height: 24),

            ...children,

            const SizedBox(height: 24),
            // Botão Aplicar
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAplicar,
                icon: const Icon(Icons.check),
                label: const AppText('Aplicar Filtros',
                    type: AppTextType.button, color: Colors.white),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppLayout.borderMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seção com label + conteúdo.
class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label,
              type: AppTextType.caption,
              color: AppColors.textSecondary,
              bold: true),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Chips de seleção "Todos / Voltaria / Não Voltaria".
class _VoltariaChips extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _VoltariaChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _buildChip(context, null, 'Todos', Icons.filter_list),
        _buildChip(context, true, 'Voltaria', Icons.thumb_up),
        _buildChip(context, false, 'Não Voltaria', Icons.thumb_down),
      ],
    );
  }

  Widget _buildChip(
      BuildContext ctx, bool? chipValue, String label, IconData icon) {
    final selected = value == chipValue;
    return FilterChip(
      selected: selected,
      avatar: Icon(icon,
          size: 16,
          color: selected ? Colors.white : AppColors.textSecondary),
      label: AppText(label,
          type: AppTextType.caption,
          color: selected ? Colors.white : AppColors.textPrimary),
      selectedColor: chipValue == null
          ? AppColors.info
          : chipValue
              ? AppColors.success
              : AppColors.danger,
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      side: BorderSide(
          color: selected ? Colors.transparent : Colors.grey.shade300),
      onSelected: (_) => onChanged(chipValue),
    );
  }
}

/// Dropdown de tipo de culinária.
class _TipoDropdown extends StatelessWidget {
  final List<String> tipos;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TipoDropdown(
      {required this.tipos, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: AppLayout.borderMedium,
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppLayout.borderMedium,
            borderSide: BorderSide(color: Colors.grey.shade300)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: const AppText('Todos os tipos',
          color: AppColors.textSecondary, type: AppTextType.body),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: AppText('Todos os tipos', color: AppColors.textSecondary),
        ),
        ...tipos.map((t) => DropdownMenuItem<String>(
              value: t,
              child: AppText(t),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

/// Dropdown de restaurante.
class _RestauranteDropdown extends StatelessWidget {
  final List<Restaurante> restaurantes;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _RestauranteDropdown(
      {required this.restaurantes,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: AppLayout.borderMedium,
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppLayout.borderMedium,
            borderSide: BorderSide(color: Colors.grey.shade300)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: const AppText('Todos os restaurantes',
          color: AppColors.textSecondary, type: AppTextType.body),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: AppText('Todos os restaurantes',
              color: AppColors.textSecondary),
        ),
        ...restaurantes.map((r) => DropdownMenuItem<int>(
              value: r.id,
              child: AppText(r.nome),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
