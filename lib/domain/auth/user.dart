class User {
  const User({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.userName,
    required this.email,
    required this.avatar,
    required this.celular,
    required this.role,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String userName;
  final String email;
  final String? avatar;
  final int celular;
  final Role role;

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      userName: map['userName'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String?,
      celular: map['celular'] as int,
      role: Role.fromJson(map['role']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'userName': userName,
      'email': email,
      'avatar': avatar,
      'celular': celular,
      'role': {
        'id': role.id,
        'nombre': role.nombre,
      }
    };
  }
}

class Role {
  const Role({
    required this.id,
    required this.nombre,
  });

  final int id;
  final String nombre;

  factory Role.fromJson(Map<String, dynamic> map) {
    return Role(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
    );
  }
}
