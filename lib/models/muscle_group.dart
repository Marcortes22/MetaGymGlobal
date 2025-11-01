class MuscleGroup {
  final String id;
  final String name;
  final String description;

  MuscleGroup({
    required this.id,
    required this.name,
    required this.description,
  });

  factory MuscleGroup.fromDocument(String id, Map<String, dynamic> data) {
    return MuscleGroup(
      id: id,
      name: data['name'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description};
  }
}
