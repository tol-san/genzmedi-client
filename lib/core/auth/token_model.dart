import 'package:equatable/equatable.dart';

class TokenModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType];
}

class PasswordResetVerification extends Equatable {
  final String resetToken;
  final int expiresIn;

  const PasswordResetVerification({
    required this.resetToken,
    required this.expiresIn,
  });

  factory PasswordResetVerification.fromJson(Map<String, dynamic> json) {
    return PasswordResetVerification(
      resetToken: json['reset_token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  @override
  List<Object?> get props => [resetToken, expiresIn];
}
