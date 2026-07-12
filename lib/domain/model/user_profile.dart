// lib/domain/model/user_profile.dart

class UserProfile {
  final int idPerfil;
  final String username;
  final String email;
  final String cedula;
  final String telefono;
  final String direccion;
  final String? fotoPerfil;
  final String? fechaNacimiento;

  const UserProfile({
    required this.idPerfil,
    required this.username,
    required this.email,
    required this.cedula,
    required this.telefono,
    required this.direccion,
    this.fotoPerfil,
    this.fechaNacimiento,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        idPerfil: json['id_perfil'] as int,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        cedula: json['cedula'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        direccion: json['direccion'] as String? ?? '',
        fotoPerfil: json['foto_perfil'] as String?,
        fechaNacimiento: json['fecha_nacimiento'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id_perfil': idPerfil,
        'username': username,
        'email': email,
        'cedula': cedula,
        'telefono': telefono,
        'direccion': direccion,
        'foto_perfil': fotoPerfil,
        'fecha_nacimiento': fechaNacimiento,
      };

  UserProfile copyWith({
    int? idPerfil,
    String? username,
    String? email,
    String? cedula,
    String? telefono,
    String? direccion,
    String? fotoPerfil,
    String? fechaNacimiento,
  }) =>
      UserProfile(
        idPerfil: idPerfil ?? this.idPerfil,
        username: username ?? this.username,
        email: email ?? this.email,
        cedula: cedula ?? this.cedula,
        telefono: telefono ?? this.telefono,
        direccion: direccion ?? this.direccion,
        fotoPerfil: fotoPerfil ?? this.fotoPerfil,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      );
}