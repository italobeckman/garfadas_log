class Prato {
  int? id;
  int restauranteId;
  String? nomeLocal; // Utilizado apenas para queries
  String descricaoPrato;
  String data;               // Formato: dd/MM/yyyy
  double notaComida;         // 1.0 a 5.0
  double notaCustoBeneficio; // 1.0 a 5.0
  bool voltaria;           
  String? observacoes;
  String? imagePath;

  Prato({
    this.id,
    required this.restauranteId,
    this.nomeLocal,
    required this.descricaoPrato,
    required this.data,
    required this.notaComida,
    required this.notaCustoBeneficio,
    required this.voltaria,
    this.observacoes,
    this.imagePath,
  });

  double get mediaAvaliacao =>
      (notaComida * 0.6) + (notaCustoBeneficio * 0.4);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restauranteId': restauranteId,
      'descricaoPrato': descricaoPrato,
      'data': data,
      'notaComida': notaComida,
      'notaCustoBeneficio': notaCustoBeneficio,
      'voltaria': voltaria ? 1 : 0,
      'observacoes': observacoes,
      'imagePath': imagePath,
    };
  }

  factory Prato.fromMap(Map<String, dynamic> map) {
    return Prato(
      id: map['id'],
      restauranteId: map['restauranteId'],
      nomeLocal: map['nomeLocal'],
      descricaoPrato: map['descricaoPrato'],
      data: map['data'],
      notaComida: map['notaComida'],
      notaCustoBeneficio: map['notaCustoBeneficio'],
      voltaria: map['voltaria'] == 1,
      observacoes: map['observacoes'],
      imagePath: map['imagePath'],
    );
  }
}
