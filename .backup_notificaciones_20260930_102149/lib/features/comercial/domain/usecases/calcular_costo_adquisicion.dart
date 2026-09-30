class CalcularCostoAdquisicion {
  double call({
    required double costoUnitario,
    double? fleteUnitario,
    double? seguroUnitario,
    double? arancelesUnitario,
    double? gastosUnitario,
  }) {
    final flete = fleteUnitario ?? 0.0;
    final seguro = seguroUnitario ?? 0.0;
    final aranceles = arancelesUnitario ?? 0.0;
    final gastos = gastosUnitario ?? 0.0;

    return costoUnitario + flete + seguro + aranceles + gastos;
  }
}
