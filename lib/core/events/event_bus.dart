import 'dart:async';

// Bus de eventos centralizado para la comunicación desacoplada entre módulos (SSOT / Core)
class EventBus {
  factory EventBus() => _instance;
  EventBus._internal();
  static final EventBus _instance = EventBus._internal();

  final _controller = StreamController<AppEvent>.broadcast();

  // Publicar un evento hacia el núcleo y otros módulos suscritos
  void fire(AppEvent event) {
    _controller.add(event);
  }

  // Escuchar eventos específicos o generales
  Stream<T> on<T extends AppEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void dispose() {
    _controller.close();
  }
}

abstract class AppEvent {
  const AppEvent();
}

class ModuleCommunicationEvent extends AppEvent {
  const ModuleCommunicationEvent({
    required this.sourceModule,
    required this.targetModule,
    required this.action,
    this.payload,
  });
  final String sourceModule;
  final String targetModule;
  final String action;
  final Map<String, dynamic>? payload;
}
