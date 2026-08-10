<?php
/*
Tabla: ajuste_inventario
Guarda el registro de cada ajuste realizado
*/

function create_ajuste_inventario_table($conexion)
{
    $sql = "CREATE TABLE IF NOT EXISTS ajuste_inventario (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_producto INT NOT NULL,
        tipo_ajuste ENUM('positivo', 'negativo') NOT NULL,
        cantidad DECIMAL(10,2) NOT NULL,
        motivo VARCHAR(100) NOT NULL,
        observaciones TEXT NULL,
        usuario_id INT NOT NULL,
        fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_producto) REFERENCES inventario(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;";

    if ($conexion->query($sql) === TRUE) {
        echo "Tabla ajuste_inventario creada correctamente\n";
    } else {
        echo "Error creando tabla: " . $conexion->error . "\n";
    }
}
