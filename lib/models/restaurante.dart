class Restaurante {
  int? id;
  String nome;
  String tipo;

  // Campos calculados em tempo de execução com base nos pratos associados
  double? notaGeral;
  bool? voltaria;
  int totalPratos;

  Restaurante({
    this.id,
    required this.nome,
    required this.tipo,
    this.notaGeral,
    this.voltaria,
    this.totalPratos = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
    };
  }

  factory Restaurante.fromMap(Map<String, dynamic> map) {
    return Restaurante(
      id: map['id'],
      nome: map['nome'],
      tipo: map['tipo'],
    );
  }
}
