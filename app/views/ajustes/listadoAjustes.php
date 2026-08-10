<h3>Historial de Ajustes de Inventario</h3>
<table border="1" cellpadding="5">
    <tr>
        <th>Fecha</th>
        <th>Producto</th>
        <th>Tipo</th>
        <th>Cantidad</th>
        <th>Motivo</th>
        <th>usuarioId</th>
    </tr>
    <?php foreach($lista as $fila): ?>
    <tr>
        <td><?= $fila['fecha'] ?></td>
        <td><?= $fila['producto'] ?></td>
        <td><?= $fila['tipo_ajuste'] ?></td>
        <td><?= $fila['cantidad'] ?></td>
        <td><?= $fila['motivo'] ?></td>
        <td><?= $fila['usuarioId'] ?></td>
    </tr>
    <?php endforeach; ?>
</table>
