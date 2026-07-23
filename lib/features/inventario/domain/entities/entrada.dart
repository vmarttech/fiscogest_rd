class Entrada {
  final int? id;
  final int productoId;
  final double cantidad;
  final String motivo;
  final String usuario;
  final DateTime fecha;

  const Entrada({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.motivo,
    required this.usuario,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productoId': productoId,
      'cantidad': cantidad,
      'motivo': motivo,
      'usuario': usuario,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Entrada.fromMap(Map<String, dynamic> map) {
    return Entrada(
      id: map['id'] as int?,
      productoId: map['productoId'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
      motivo: map['motivo'] as String,
      usuario: map['usuario'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }
}
