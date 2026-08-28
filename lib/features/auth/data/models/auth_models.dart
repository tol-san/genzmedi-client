import 'package:equatable/equatable.dart';

/// Request payload for logging in
class LoginRequest extends Equatable {
  final String username;
  final String password;

  const LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  @override
  List<Object?> get props => [username, password];
}

/// Request payload for user registration
class RegisterRequest extends Equatable {
  final String username;
  final String email;
  final String password;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
      };

  @override
  List<Object?> get props => [username, email, password];
}

/// Request payload for initiating password reset
class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};

  @override
  List<Object?> get props => [email];
}

/// Request payload for completing password reset
class ResetPasswordRequest extends Equatable {
  final String token;
  final String newPassword;
  final String? email;

  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'new_password': newPassword,
        if (email != null && email!.isNotEmpty) 'email': email,
      };

  @override
  List<Object?> get props => [token, newPassword, email];
}

/// Category/Topic interest model for onboarding and user personalization
class InterestModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? icon;

  const InterestModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory InterestModel.fromJson(Map<String, dynamic> json) {
    return InterestModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? json['name']?.toString().toLowerCase() ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        if (icon != null) 'icon': icon,
      };

  @override
  List<Object?> get props => [id, name, slug, icon];
}
