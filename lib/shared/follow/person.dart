/// Someone in a followers, following or requests list.
class Person {
  const Person({
    required this.id,
    required this.name,
    this.username = '',
    this.imageUrl,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    String text(String key) => (json[key] as String? ?? '').trim();
    final image = text('imgId');
    return Person(
      id: text('id'),
      name: text('name'),
      username: text('username'),
      imageUrl: image.isEmpty ? null : image,
    );
  }

  final String id;
  final String name;
  final String username;
  final String? imageUrl;
}

/// The three lists a person keeps.
enum PeopleList { followers, following, requests }
