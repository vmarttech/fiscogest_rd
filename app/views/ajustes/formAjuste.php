<form action="index.php?c=ajusteInventario&a=guardar" method="POST">
    <label>Producto:</label>
    <select name="id_producto" required>
        <!-- cargar productos dinámicamente -->
    </select>

    <label>Tipo de ajuste:</label>
    <select name="tipo_ajuste" required>
        <option value="positivo">Aumentar stock</option>
        <option value="negativo">Disminuir stock</option>
    </select>

    <label>Cantidad:</label>
    <input type="number" name="cantidad" min="1" required>

    <label>Motivo:</label>
    <select name="motivo" required>
        <option>Conteo físico</option>
        <option>Devolución proveedor</option>
        <option>Merma / Daño</option>
        <option>Error registro</option>
        <option>Otro</option>
    </select>

    <label>Observaciones:</label>
    <textarea name="observaciones" rows="3"></textarea>

    <button type="submit">Guardar Ajuste</button>
</form>
