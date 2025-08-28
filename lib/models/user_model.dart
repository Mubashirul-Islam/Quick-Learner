class Student {
  final String sid;
  final String email;
  final String? name;
  final String? edu;

  const Student({required this.sid, required this.email, this.name, this.edu});

  Student copyWith({String? name, String? edu}) {
    return Student(
      sid: sid,
      email: email,
      name: name ?? this.name,
      edu: edu ?? this.edu,
    );
  }

  Map<String, dynamic> toMap() {
    return {'sid': sid, 'email': email, 'name': name, 'edu': edu};
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      sid: map['sid'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      edu: map['edu'] as String?,
    );
  }
}

class Tutor {
  final String tid;
  final String email;
  final String? name;
  final String? edu;
  final double? fee;
  final double? rating;

  const Tutor({
    required this.tid,
    required this.email,
    this.name,
    this.edu,
    this.fee,
    this.rating,
  });

  Tutor copyWith({String? name, String? edu, double? fee, double? rating}) {
    return Tutor(
      tid: tid,
      email: email,
      name: name ?? this.name,
      edu: edu ?? this.edu,
      fee: fee ?? this.fee,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tid': tid,
      'email': email,
      'name': name,
      'edu': edu,
      'fee': fee,
      'rating': rating,
    };
  }

  factory Tutor.fromMap(Map<String, dynamic> map) {
    return Tutor(
      tid: map['tid'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      edu: map['edu'] as String?,
      fee: (map['fee'] is int)
          ? (map['fee'] as int).toDouble()
          : map['fee'] as double?,
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : map['rating'] as double?,
    );
  }
}
