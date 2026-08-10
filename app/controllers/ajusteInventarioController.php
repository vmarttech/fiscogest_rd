<?php

require_once "../models/AjusteInventario.php";
require_once "../models/Inventario.php";
require_once "../models/Kardex.php";
require_once "../../includes/sesion.php";

class ajusteInventarioController
{
    private $db;
    private $ajuste;
    private $inventario;
    private $kardex;

    public function __construct($conexionBase)
    {
        $this->db = $conexionBase;
        $this->ajuste = new AjusteInventario($this->db);
        $this->inventario = new Inventario($this->db);
        $this->kardex = new Kardex($this->db);
    }

    // Cargar formulario de ajuste
    public function crear()
    {
        require_once "../views/ajustes/formAjuste.php";
    }

    // Procesar guardado del ajuste
    public function guardar()
    {
        // 1. Recibir datos del formulario
        // 2. Validar: tipo (+/-), cantidad > 0, motivo, usuarioId de sesión
        // 3. Registrar en ajuste_inventario
        // 4. Actualizar existencias en inventario
        // 5. Registrar movimiento en kardex
        // 6. Redirigir con mensaje
    }

    // Mostrar listado de ajustes
    public function index()
    {
        $lista = $this->ajuste->listar();
        require_once "../views/ajustes/listadoAjustes.php";
    }
}
