import 'package:casa_empenio_pe/domain/domain.dart';

class UserEntity {
  const UserEntity({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.userName,
    required this.email,
    required this.avatar,
    required this.celular,
    required this.role,
    required this.pagos,
    required this.prestamos,
    required this.createdAt,
    required this.prestamosAdmin,
    required this.updatedAt,
    required this.ventas,
    required this.isAdmin,
    required this.sucursal,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String userName;
  final String email;
  final String? avatar;
  final int? celular;
  final RoleEntity? role;
  final List<LoansEntity>? prestamos;
  final List<LoansEntity>? prestamosAdmin;
  final List<PayEntity>? pagos;
  final List<SalesEntity>? ventas;
  final String? createdAt;
  final String? updatedAt;
  final bool? isAdmin;
  final SucursalEntity? sucursal;

  String get fullName => '$nombre $apellido';

  static List<UserEntity> listGetUsersFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map['body'][0] as List<dynamic>;
    return list.map((e) => userFromMap(e as Map<String, dynamic>)).toList();
  }

  static UserEntity userFromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      userName: map['userName'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String?,
      celular: map['celular'] as int?,
      role: map['role'] != null ? roleFromMap(map['role']) : null,
      isAdmin: map['isAdmin'] as bool?,
      createdAt: null,
      pagos: null,
      prestamos: null,
      prestamosAdmin: null,
      updatedAt: null,
      ventas: null,
      sucursal: map['sucursal'] != null
          ? SucursalEntity.sucursalFromMap(
              map['sucursal'],
            )
          : null,
    );
  }

  static RoleEntity roleFromMap(Map<String, dynamic> map) => RoleEntity(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
      );

  factory UserEntity.fromJson(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      userName: map['userName'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String?,
      celular: map['celular'] as int?,
      role: RoleEntity.fromJson(map['role']),
      createdAt: '',
      pagos: null,
      prestamos: null,
      prestamosAdmin: null,
      updatedAt: null,
      ventas: null,
      isAdmin: map['isAdmin'] as bool?,
      sucursal: map['sucursal'] != null
          ? SucursalEntity.sucursalFromMap(
              map['sucursal'],
            )
          : null,
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
        'id': role?.id,
        'nombre': role?.nombre,
      },
      'isAdmin': isAdmin,
      'sucursal': {
        'id': sucursal?.id,
        'nombre': sucursal?.nombre,
        'direccion': sucursal?.direccion,
        'createdAt': sucursal?.createdAt,
        'updatedAt': sucursal?.updatedAt,
        'deletedAt': sucursal?.deletedAt,
      },
    };
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, nombre: $nombre, apellido: $apellido, userName: $userName, email: $email, avatar: $avatar, celular: $celular, role: $role, pagos: $pagos, prestamos: $prestamos, createdAt: $createdAt, prestamosAdmin: $prestamosAdmin, updatedAt: $updatedAt, ventas: $ventas, isAdmin: $isAdmin, sucursal: $sucursal)';
  }
}

class RoleEntity {
  const RoleEntity({
    required this.id,
    required this.nombre,
  });

  final int id;
  final String nombre;

  factory RoleEntity.fromJson(Map<String, dynamic> map) {
    return RoleEntity(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
    );
  }
}
