// lib/domain/model/notificacion.dart

class Notificacion {
  final int idNotificacion;
  final int idUsuario;
  final String titulo;
  final String mensaje;
  final bool leido;
  final DateTime? fechaCreacion;

  const Notificacion({
    required this.idNotificacion,
    required this.idUsuario,
    required this.titulo,
    required this.mensaje,
    required this.leido,
    this.fechaCreacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        idNotificacion: j['id_notificacion'] as int,
        idUsuario: j['id_usuario'] as int,
        titulo: j['titulo']?.toString() ?? '',
        mensaje: j['mensaje']?.toString() ?? '',
        leido: j['leido'] == true,
        fechaCreacion: j['fecha_creacion'] != null
            ? DateTime.tryParse(j['fecha_creacion'].toString())
            : null,
      );

  Notificacion copyWith({
    int? idNotificacion,
    int? idUsuario,
    String? titulo,
    String? mensaje,
    bool? leido,
    DateTime? fechaCreacion,
  }) {
    return Notificacion(
      idNotificacion: idNotificacion ?? this.idNotificacion,
      idUsuario: idUsuario ?? this.idUsuario,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      leido: leido ?? this.leido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

class PaginatedNotificaciones {
  final int count;
  final String? next;
  final String? previous;
  final List<Notificacion> results;

  const PaginatedNotificaciones({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedNotificaciones.fromJson(Map<String, dynamic> j) =>
      PaginatedNotificaciones(
        count: j['count'] as int,
        next: j['next'] as String?,
        previous: j['previous'] as String?,
        results: (j['results'] as List)
            .map((e) => Notificacion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
