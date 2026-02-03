class Profile {
  final String id;
  final String name;
  final String email;
  final String? phone;


  Profile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,

  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,

    };
  }
}
