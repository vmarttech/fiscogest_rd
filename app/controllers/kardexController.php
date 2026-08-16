<?php

require_once "../models/Kardex.php";

class kardexController
{
    private $db;
    private $kardex;

    public function __construct($conexionBase)
    {
        $this->db = $conexionBase;
        $this->kardex = new Kardex($this->db);
    }

    // Ver movimientos de un producto
    public function verMovimientos($productoId)
    {
        // lógica de visualización
    }
}
