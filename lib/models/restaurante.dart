class Restaurante {
  int? id;
  String nome;
  String tipo;
  bool? overrideVoltaria; // null = use calculated, true/false = override

  // Campos calculados em tempo de execução com base nos pratos associados
  double? notaGeral;
  bool? voltaria;
  int totalPratos;
  String? ultimoPrato;

  Restaurante({
    this.id,
    required this.nome,
    required this.tipo,
    this.overrideVoltaria,
    this.notaGeral,
    this.voltaria,
    this.totalPratos = 0,
    this.ultimoPrato,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'overrideVoltaria': overrideVoltaria == null ? null : (overrideVoltaria! ? 1 : 0),
    };
  }

  factory Restaurante.fromMap(Map<String, dynamic> map) {
    return Restaurante(
      id: map['id'],
      nome: map['nome'],
      tipo: map['tipo'],
      overrideVoltaria: map['overrideVoltaria'] == null ? null : map['overrideVoltaria'] == 1,
    );
  }
}

