/// Ítem de checklist de certificación / adopción de circular.
class EcfeChecklistItem {
  const EcfeChecklistItem({
    required this.id,
    required this.label,
    this.done = false,
    this.doneAt,
    this.categoria = 'general',
  });

  final String id;
  final String label;
  final bool done;
  final DateTime? doneAt;
  final String categoria;

  EcfeChecklistItem copyWith({
    bool? done,
    DateTime? doneAt,
  }) {
    return EcfeChecklistItem(
      id: id,
      label: label,
      done: done ?? this.done,
      doneAt: doneAt ?? this.doneAt,
      categoria: categoria,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'done': done,
        'doneAt': doneAt?.toIso8601String(),
        'categoria': categoria,
      };

  static EcfeChecklistItem fromJson(Map<String, dynamic> m) {
    return EcfeChecklistItem(
      id: '${m['id']}',
      label: '${m['label'] ?? ''}',
      done: m['done'] == true,
      doneAt: m['doneAt'] != null
          ? DateTime.tryParse('${m['doneAt']}')
          : null,
      categoria: '${m['categoria'] ?? 'general'}',
    );
  }
}
