class Role {
  final String id;
  final String name;
  final String description;

  Role({required this.id, required this.name, required this.description});

  factory Role.fromMap(String id, Map<String, dynamic> data) {
    return Role(id: id, name: data['name'], description: data['description']);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description};
  }
}
