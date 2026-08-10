<?php
/*
Tabla: kardex
Registro detallado de movimientos de stock
*/

function create_kardex_table($conexion)
{
    $sql = "CREATE TABLE IF NOT EXISTS kardex (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_producto INT NOT NULL,
        tipo_movimiento VARCHAR(50) NOT NULL, -- Ajuste entrada / Ajuste salida
        cantidad DECIMAL(10,2) NOT NULL,
        saldo_actual DECIMAL(10,2) NOT NULL,
        referencia_id INT NULL, -- ID del ajuste o documento
        motivo VARCHAR(100) NOT NULL,
        usuarioId_id INT NOT NULL,
        fecha_movimiento DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_producto) REFERENCES inventario(id),
        FOREIGN KEY (usuarioId_id) REFERENCES usuarioIds(id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";

    if ($conexion->query($sql) === TRUE) {
        echo "Tabla kardex creada correctamente\n";
    } else {
        echo "Error creando tabla: " . $conexion->error . "\n";
    }
}
