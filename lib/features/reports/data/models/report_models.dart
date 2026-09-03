import 'package:equatable/equatable.dart';

enum ReportTargetType { user, post, comment, community, chatMessage }

extension ReportTargetTypeX on ReportTargetType {
  String get apiValue => switch (this) {
    ReportTargetType.chatMessage => 'chat_message',
    _ => name,
  };

  String get label => switch (this) {
    ReportTargetType.user => 'account',
    ReportTargetType.post => 'post',
    ReportTargetType.comment => 'comment',
    ReportTargetType.community => 'community',
    ReportTargetType.chatMessage => 'chat message',
  };
}

enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  hateSpeech,
  violence,
  copyright,
  other,
}

extension ReportReasonX on ReportReason {
  String get apiValue => switch (this) {
    ReportReason.inappropriateContent => 'inappropriate_content',
    ReportReason.hateSpeech => 'hate_speech',
    _ => name,
  };

  String get label => switch (this) {
    ReportReason.spam => 'Spam',
    ReportReason.harassment => 'Harassment',
    ReportReason.inappropriateContent => 'Inappropriate content',
    ReportReason.hateSpeech => 'Hate speech',
    ReportReason.violence => 'Violence or dangerous acts',
    ReportReason.copyright => 'Copyright violation',
    ReportReason.other => 'Other',
  };

  String get helper => switch (this) {
    ReportReason.spam => 'Unwanted promotion, scams, or repetitive content',
    ReportReason.harassment => 'Bullying, threats, or targeted abuse',
    ReportReason.inappropriateContent =>
      'Sexual, graphic, or otherwise unsuitable content',
    ReportReason.hateSpeech => 'Attacks based on identity or protected traits',
    ReportReason.violence => 'Violent threats, harm, or dangerous behavior',
    ReportReason.copyright => 'Content that infringes intellectual property',
    ReportReason.other => 'A concern that is not listed above',
  };
}

class ReportModel extends Equatable {
  final String id;
  final String reporterId;
  final String? reporterUsername;
  final ReportTargetType targetType;
  final String targetId;
  final String? communityId;
  final String reason;
  final String? description;
  final String status;
  final String? resolutionAction;
  final String? resolutionNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    this.reporterUsername,
    required this.targetType,
    required this.targetId,
    this.communityId,
    required this.reason,
    this.description,
    required this.status,
    this.resolutionAction,
    this.resolutionNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final type = (json['report_type'] as String? ?? 'post').toLowerCase();
    return ReportModel(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      reporterUsername: json['reporter_username'] as String?,
      targetType: switch (type) {
        'user' => ReportTargetType.user,
        'comment' => ReportTargetType.comment,
        'community' => ReportTargetType.community,
        'chat_message' => ReportTargetType.chatMessage,
        _ => ReportTargetType.post,
      },
      targetId: json['target_id']?.toString() ?? '',
      communityId: json['community_id']?.toString(),
      reason: json['reason'] as String? ?? 'other',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      resolutionAction: json['resolution_action'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  bool get isClosed => status == 'RESOLVED' || status == 'REJECTED';

  @override
  List<Object?> get props => [
    id,
    reporterId,
    reporterUsername,
    targetType,
    targetId,
    communityId,
    reason,
    description,
    status,
    resolutionAction,
    resolutionNotes,
    reviewedBy,
    reviewedAt,
    createdAt,
    updatedAt,
  ];
}

class PaginatedReports {
  final List<ReportModel> items;
  final int total;
  final int limit;
  final int offset;

  const PaginatedReports({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory PaginatedReports.fromJson(Map<String, dynamic> json) =>
      PaginatedReports(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        offset: (json['offset'] as num?)?.toInt() ?? 0,
      );
}
