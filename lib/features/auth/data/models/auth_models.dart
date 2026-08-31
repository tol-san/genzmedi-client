import 'package:equatable/equatable.dart';

/// Request payload for logging in
class LoginRequest extends Equatable {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};

  @override
  List<Object?> get props => [username, password];
}

/// Request payload for user registration (legacy / direct)
class RegisterRequest extends Equatable {
  final String? username;
  final String email;
  final String password;

  const RegisterRequest({
    this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    if (username != null) 'username': username,
    'email': email,
    'password': password,
  };

  @override
  List<Object?> get props => [username, email, password];
}

/// Request payload for requesting a signup OTP verification code
class SignupOtpRequest extends Equatable {
  final String email;
  final String password;

  const SignupOtpRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};

  @override
  List<Object?> get props => [email, password];
}

/// Request payload for verifying signup OTP code
class SignupVerifyOtpRequest extends Equatable {
  final String email;
  final String otp;

  const SignupVerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};

  @override
  List<Object?> get props => [email, otp];
}

/// Response payload for checking username availability
class CheckUsernameResponse extends Equatable {
  final bool available;
  final String username;

  const CheckUsernameResponse({
    required this.available,
    required this.username,
  });

  factory CheckUsernameResponse.fromJson(Map<String, dynamic> json) =>
      CheckUsernameResponse(
        available: json['available'] as bool? ?? false,
        username: json['username'] as String? ?? '',
      );

  @override
  List<Object?> get props => [available, username];
}

/// Request payload for initiating password reset
class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};

  @override
  List<Object?> get props => [email];
}

/// Request payload for validating 6-digit OTP code
class VerifyOtpRequest extends Equatable {
  final String email;
  final String otp;

  const VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};

  @override
  List<Object?> get props => [email, otp];
}

/// Request payload for completing password reset
class ResetPasswordRequest extends Equatable {
  final String token;
  final String newPassword;

  const ResetPasswordRequest({required this.token, required this.newPassword});

  Map<String, dynamic> toJson() => {
    'token': token,
    'new_password': newPassword,
  };

  @override
  List<Object?> get props => [token, newPassword];
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
      slug:
          json['slug'] as String? ??
          json['name']?.toString().toLowerCase() ??
          '',
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
