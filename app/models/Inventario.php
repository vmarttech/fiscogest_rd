<?php

class Inventario
{
    private $conexion;

    public function __construct($db)
    {
        $this->conexion = $db;
    }

    // Actualizar existencias tras el ajuste
    public function actualizarExistencias($idProducto, $cantidad, $tipoAjuste)
    {
        // si es positivo += cantidad, si negativo -= cantidad
    }

    // Consultar stock actual
    public function obtenerStock($idProducto)
    {
        // lógica de consulta
    }
}
