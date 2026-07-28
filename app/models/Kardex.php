<?php

class Kardex
{
    private $conexion;

    public function __construct($db)
    {
        $this->conexion = $db;
    }

    // Registrar movimiento en kardex
    public function registrarMovimiento($datos)
    {
        // tipo movimiento, cantidad, saldo, referencia, motivo
    }
}
