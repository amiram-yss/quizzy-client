class User {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final String token;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      picture: json['picture'],
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': id,
      'email': email,
      'name': name,
      'picture': picture,
      'token': token,
    };
  }
}