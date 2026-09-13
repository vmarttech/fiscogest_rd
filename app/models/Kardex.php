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
        // 1. Obtener saldo anterior del producto (último saldo registrado)
        $saldo_anterior = 0;
        $consulta = $this->conexion->prepare("
            SELECT saldo_final 
            FROM kardex 
            WHERE producto_id = ? 
            ORDER BY id DESC 
            LIMIT 1
        ");
        $consulta->execute([$datos['producto_id']]);
        $fila = $consulta->fetch(PDO::FETCH_ASSOC);
        
        if ($fila) {
            $saldo_anterior = floatval($fila['saldo_final']);
        }

        // 2. Calcular nuevo saldo
        $cantidad = floatval($datos['cantidad']);
        if ($datos['tipo_movimiento'] === 'entrada') {
            $saldo_nuevo = $saldo_anterior + $cantidad;
        } else {
            $saldo_nuevo = $saldo_anterior - $cantidad;
        }

        // 3. Insertar movimiento en la tabla kardex
        $insertar = $this->conexion->prepare("
            INSERT INTO kardex 
            (producto_id, fecha, tipo_movimiento, cantidad, saldo_anterior, saldo_final, costo_unitario, documento, motivo)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $insertar->execute([
            $datos['producto_id'],
            $datos['fecha'],
            $datos['tipo_movimiento'],
            $cantidad,
            $saldo_anterior,
            $saldo_nuevo,
            $datos['costo_unitario'] ?? 0,
            $datos['documento'] ?? null,
            $datos['motivo'] ?? 'Compra'
        ]);

        // 4. Devolver saldo actualizado
        return $saldo_nuevo;
    }
}
