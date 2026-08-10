<?php

class AjusteInventario
{
    private $conexion;

    public function __construct($db)
    {
        $this->conexion = $db;
    }

    // Registrar ajuste positivo / negativo
    public function registrar($datos)
    {
        // lógica: tipo, cantidad, motivo, usuarioId, observaciones
    }

    // Obtener listado de ajustes
    public function listar()
    {
        // lógica de consulta
    }
}
