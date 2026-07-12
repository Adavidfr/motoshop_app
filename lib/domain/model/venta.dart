// lib/domain/model/venta.dart

class Financiamiento {
  final int idFinanciamiento;
  final int idVenta;
  final String entidadFinanciera;
  final double montoFinanciado;
  final double tasaInteres;
  final int plazoMeses;
  final double cuotaMensual;
  final String estado;

  const Financiamiento({
    required this.idFinanciamiento,
    required this.idVenta,
    required this.entidadFinanciera,
    required this.montoFinanciado,
    required this.tasaInteres,
    required this.plazoMeses,
    required this.cuotaMensual,
    required this.estado,
  });

  factory Financiamiento.fromJson(Map<String, dynamic> json) => Financiamiento(
    idFinanciamiento: json['id_financiamiento'] as int,
    idVenta:          json['id_venta'] as int,
    entidadFinanciera:json['entidad_financiera'] as String? ?? '',
    montoFinanciado:  double.parse((json['monto_financiado'] ?? 0).toString()),
    tasaInteres:      double.parse((json['tasa_interes'] ?? 0).toString()),
    plazoMeses:       json['plazo_meses'] as int? ?? 0,
    cuotaMensual:     double.parse((json['cuota_mensual'] ?? 0).toString()),
    estado:           json['estado'] as String? ?? '',
  );
}

class Venta {
  final int idVenta;
  final int idPedido;
  final String usernameCliente;
  final int idUsuarioCliente;
  final String usernameVendedor;
  final int idUsuarioVendedor;
  final double totalVenta;
  final String estado;
  final DateTime fechaVenta;
  final int numFinanciamientos;
  final List<Financiamiento> financiamientos;

  const Venta({
    required this.idVenta,
    required this.idPedido,
    required this.usernameCliente,
    required this.idUsuarioCliente,
    required this.usernameVendedor,
    required this.idUsuarioVendedor,
    required this.totalVenta,
    required this.estado,
    required this.fechaVenta,
    required this.numFinanciamientos,
    required this.financiamientos,
  });

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
    idVenta:           json['id_venta'] as int,
    idPedido:          json['id_pedido'] as int,
    usernameCliente:   json['username_cliente'] as String? ?? 'Desconocido',
    idUsuarioCliente:  json['id_usuario_cliente'] as int? ?? 0,
    usernameVendedor:  json['username_vendedor'] as String? ?? 'Desconocido',
    idUsuarioVendedor: json['id_usuario_vendedor'] as int? ?? 0,
    totalVenta:        double.parse((json['total_venta'] ?? 0).toString()),
    estado:            json['estado'] as String? ?? 'completada',
    fechaVenta:        DateTime.parse(json['fecha_venta'] as String),
    numFinanciamientos:json['num_financiamientos'] as int? ?? 0,
    financiamientos:   (json['financiamientos'] as List<dynamic>? ?? [])
        .map((e) => Financiamiento.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Venta copyWith({
    int? idVenta,
    int? idPedido,
    String? usernameCliente,
    int? idUsuarioCliente,
    String? usernameVendedor,
    int? idUsuarioVendedor,
    double? totalVenta,
    String? estado,
    DateTime? fechaVenta,
    int? numFinanciamientos,
    List<Financiamiento>? financiamientos,
  }) => Venta(
    idVenta:           idVenta ?? this.idVenta,
    idPedido:          idPedido ?? this.idPedido,
    usernameCliente:   usernameCliente ?? this.usernameCliente,
    idUsuarioCliente:  idUsuarioCliente ?? this.idUsuarioCliente,
    usernameVendedor:  usernameVendedor ?? this.usernameVendedor,
    idUsuarioVendedor: idUsuarioVendedor ?? this.idUsuarioVendedor,
    totalVenta:        totalVenta ?? this.totalVenta,
    estado:            estado ?? this.estado,
    fechaVenta:        fechaVenta ?? this.fechaVenta,
    numFinanciamientos:numFinanciamientos ?? this.numFinanciamientos,
    financiamientos:   financiamientos ?? this.financiamientos,
  );
}
