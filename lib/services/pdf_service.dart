import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/prato.dart';
import '../models/restaurante.dart';

/// Serviço responsável pela geração e entrega de relatórios em PDF.
///
/// A View apenas fornece a lista de dados; este serviço cuida de:
///  1. Montar o layout do documento (tabelas + estatísticas).
///  2. Entregar o arquivo conforme a plataforma (Windows → open_file; Mobile → share_plus; Web → printing).
class PdfService {
  // ─── Paleta do relatório (espelha AppColors sem depender de Flutter material) ───
  static final _primary = PdfColor.fromHex('#FF5722');
  static final _background = PdfColor.fromHex('#F8F9FA');
  static final _textPrimary = PdfColor.fromHex('#212529');
  static final _textSecondary = PdfColor.fromHex('#6C757D');
  static final _success = PdfColor.fromHex('#28A745');
  static final _danger = PdfColor.fromHex('#DC3545');
  static final _border = PdfColor.fromHex('#DEE2E6');

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Gera e entrega um relatório de restaurantes.
  Future<void> exportarRelatorioRestaurantes(
      List<Restaurante> lista, String filtroDescricao) async {
    if (lista.isEmpty) {
      throw Exception('Nenhum restaurante para exportar.');
    }
    final bytes = await _buildPdfRestaurantes(lista, filtroDescricao);
    await _deliver(bytes, 'relatorio_restaurantes_${_timestamp()}.pdf');
  }

  /// Gera e entrega um relatório de pratos.
  Future<void> exportarRelatorioPratos(
      List<Prato> lista, String filtroDescricao) async {
    if (lista.isEmpty) {
      throw Exception('Nenhum prato para exportar.');
    }
    final bytes = await _buildPdfPratos(lista, filtroDescricao);
    await _deliver(bytes, 'relatorio_pratos_${_timestamp()}.pdf');
  }

  // ─── Geração de conteúdo ──────────────────────────────────────────────────

  Future<Uint8List> _buildPdfRestaurantes(
      List<Restaurante> lista, String filtroDescricao) async {
    final doc = pw.Document();
    final totalRestaurantes = lista.length;
    final comNota = lista.where((r) => r.notaGeral != null).toList();
    final mediaGeral = comNota.isEmpty
        ? null
        : comNota.map((r) => r.notaGeral!).reduce((a, b) => a + b) /
            comNota.length;
    final voltariam = lista.where((r) => r.voltaria == true).length;
    final naoVoltariam = lista.where((r) => r.voltaria == false).length;

    // Tipos únicos
    final tiposCount = <String, int>{};
    for (final r in lista) {
      tiposCount[r.tipo] = (tiposCount[r.tipo] ?? 0) + 1;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => _buildHeader('Relatório de Restaurantes', filtroDescricao),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          // ── Estatísticas ──
          _buildSectionTitle('Resumo Geral'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
                    _statCard('Total', '$totalRestaurantes', '🍽️'),
              _statCard('Voltaria', '$voltariam', '👍'),
              _statCard('Não Voltaria', '$naoVoltariam', '👎'),
              _statCard(
                'Média Geral',
                mediaGeral != null ? mediaGeral.toStringAsFixed(1) : '—',
                '⭐',
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Tipos de culinária ──
          if (tiposCount.isNotEmpty) ...[
            _buildSectionTitle('Distribuição por Tipo'),
            pw.SizedBox(height: 8),
            _buildTiposTable(tiposCount),
            pw.SizedBox(height: 16),
          ],

          // ── Tabela principal ──
          _buildSectionTitle('Listagem Detalhada'),
          pw.SizedBox(height: 8),
          _buildRestaurantesTable(lista),
        ],
      ),
    );

    return doc.save();
  }

  Future<Uint8List> _buildPdfPratos(
      List<Prato> lista, String filtroDescricao) async {
    final doc = pw.Document();
    final total = lista.length;
    final voltariam = lista.where((p) => p.voltaria).length;
    final naoVoltariam = total - voltariam;
    final mediaGeral = total == 0
        ? 0.0
        : lista.map((p) => p.mediaAvaliacao).reduce((a, b) => a + b) / total;
    final mediaComida = total == 0
        ? 0.0
        : lista.map((p) => p.notaComida).reduce((a, b) => a + b) / total;
    final mediaCusto = total == 0
        ? 0.0
        : lista.map((p) => p.notaCustoBeneficio).reduce((a, b) => a + b) /
            total;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) =>
            _buildHeader('Relatório de Avaliações', filtroDescricao),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          // ── Estatísticas ──
          _buildSectionTitle('Resumo Geral'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statCard('Total', '$total', '🍴'),
              _statCard('Média Geral', mediaGeral.toStringAsFixed(2), '⭐'),
              _statCard('Média Comida', mediaComida.toStringAsFixed(2), '🍽️'),
              _statCard('Média Custo/Ben.', mediaCusto.toStringAsFixed(2), '💰'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              _statCard('Voltaria', '$voltariam', '👍'),
              pw.SizedBox(width: 8),
              _statCard('Não Voltaria', '$naoVoltariam', '👎'),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Tabela principal ──
          _buildSectionTitle('Listagem Detalhada'),
          pw.SizedBox(height: 8),
          _buildPratosTable(lista),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Componentes de layout ────────────────────────────────────────────────

  pw.Widget _buildHeader(String titulo, String filtroDescricao) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'GarfadasLog',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              pw.Text(
                'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: _textSecondary),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            titulo,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary),
          ),
          if (filtroDescricao.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Filtros: $filtroDescricao',
              style: pw.TextStyle(fontSize: 9, color: _textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('GarfadasLog — Relatório Automático',
            style: pw.TextStyle(fontSize: 8, color: _textSecondary)),
        pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _textSecondary)),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        texto.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  pw.Widget _statCard(String label, String value, String icon) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 6),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _background,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _border, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTiposTable(Map<String, int> tiposCount) {
    final sorted = tiposCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _background),
          children: [
            _tableHeader('Tipo de Culinária'),
            _tableHeader('Quantidade'),
          ],
        ),
        for (final entry in sorted)
          pw.TableRow(
            children: [
              _tableCell(entry.key),
              _tableCell('${entry.value}'),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildRestaurantesTable(List<Restaurante> lista) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _background),
          children: [
            _tableHeader('Restaurante'),
            _tableHeader('Tipo'),
            _tableHeader('Pratos'),
            _tableHeader('Nota'),
            _tableHeader('Voltaria?'),
          ],
        ),
        for (final r in lista)
          pw.TableRow(
            children: [
              _tableCell(r.nome),
              _tableCell(r.tipo),
              _tableCell('${r.totalPratos}'),
              _tableCell(r.notaGeral != null
                  ? r.notaGeral!.toStringAsFixed(1)
                  : '—'),
              _tableCellColored(
                r.voltaria == true
                    ? 'Sim'
                    : r.voltaria == false
                        ? 'Não'
                        : '—',
                r.voltaria == true
                    ? _success
                    : r.voltaria == false
                        ? _danger
                        : _textSecondary,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildPratosTable(List<Prato> lista) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(0.9),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _background),
          children: [
            _tableHeader('Prato'),
            _tableHeader('Restaurante'),
            _tableHeader('Data'),
            _tableHeader('Comida'),
            _tableHeader('C/B'),
            _tableHeader('Média'),
            _tableHeader('Voltaria?'),
          ],
        ),
        for (final p in lista)
          pw.TableRow(
            children: [
              _tableCell(p.descricaoPrato),
              _tableCell(p.nomeLocal ?? '—'),
              _tableCell(p.data),
              _tableCell(p.notaComida.toStringAsFixed(1)),
              _tableCell(p.notaCustoBeneficio.toStringAsFixed(1)),
              _tableCell(p.mediaAvaliacao.toStringAsFixed(2)),
              _tableCellColored(
                p.voltaria ? 'Sim' : 'Não',
                p.voltaria ? _success : _danger,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, color: _textPrimary),
      ),
    );
  }

  pw.Widget _tableCellColored(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: color),
      ),
    );
  }

  // ─── Entrega multiplataforma ──────────────────────────────────────────────

  Future<void> _deliver(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // Web: usa a interface de impressão/download do browser via printing
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
      return;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: grava em arquivo temporário e abre com o leitor padrão do SO
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
      return;
    }

    // Mobile (Android / iOS): share sheet nativo
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Relatório GarfadasLog',
    );
  }

  String _timestamp() =>
      DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
}
