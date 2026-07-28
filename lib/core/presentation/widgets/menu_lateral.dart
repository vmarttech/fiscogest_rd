import 'package:flutter/material.dart';

ListTile menuLateral({
  required IconData icono,
  required String texto,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icono, color: const Color(0xFF64748B)),
    title: Text(texto, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500)),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}
