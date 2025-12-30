class User {
  final String name;
  final int age;
  final String imageUrl;
  final List<String> galleryImages;

  User({
    required this.name,
    required this.age,
    required this.imageUrl,
    this.galleryImages = const [],
  });
}
