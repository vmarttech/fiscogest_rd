<?php
/*
Tabla: inventario
Almacena el stock actual de cada producto
*/

function create_inventario_table($conexion)
{
    $sql = "CREATE TABLE IF NOT EXISTS inventario (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre_producto VARCHAR(150) NOT NULL,
        codigo_producto VARCHAR(50) NOT NULL UNIQUE,
        stock_actual DECIMAL(10,2) NOT NULL DEFAULT 0,
        costo_unitario DECIMAL(10,2) DEFAULT 0,
        fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";

    if ($conexion->query($sql) === TRUE) {
        echo "Tabla inventario creada correctamente\n";
    } else {
        echo "Error creando tabla: " . $conexion->error . "\n";
    }
}
