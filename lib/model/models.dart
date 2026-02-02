class PasswordEntry {
  String id;
  String website;
  String username;
  String password;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  PasswordEntry({
    required this.id,
    required this.website,
    required this.username,
    required this.password,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'website': website,
    'username': username,
    'password': password,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
    id: json['id'],
    website: json['website'],
    username: json['username'],
    password: json['password'],
    notes: json['notes'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}