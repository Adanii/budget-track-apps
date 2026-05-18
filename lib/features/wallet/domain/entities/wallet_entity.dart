/// Pure Dart entity — no framework or database dependencies.
class WalletEntity {
  final String id;
  final String bank;
  final String name;
  final DateTime createdAt;

  const WalletEntity({
    required this.id,
    required this.bank,
    required this.name,
    required this.createdAt,
  });

  String get displayName => name.isNotEmpty ? '$bank ($name)' : bank;

  WalletEntity copyWith({
    String? id,
    String? bank,
    String? name,
    DateTime? createdAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      bank: bank ?? this.bank,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
