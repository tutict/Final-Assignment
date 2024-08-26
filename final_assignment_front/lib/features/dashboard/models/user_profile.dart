import 'package:flutter/material.dart';

class UserProfile {
  final ImageProvider photo;
  final String name;
  final String email;

  const UserProfile({
    required this.photo,
    required this.name,
    required this.email,
  });
}
