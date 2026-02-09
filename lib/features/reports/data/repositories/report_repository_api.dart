import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/report_hive_model.dart';

class ReportRepositoryApi {
  ReportRepositoryApi({required ApiClient client, required this.accessToken})
      : _client = client;

  final ApiClient _client;
  final String? accessToken;

  Future<List<ReportHiveModel>> getAll() async {
    final token = _requireAccessToken();
    final response = await _client.getJson(
      ApiEndpoints.reports,
      accessToken: token,
    );
    final items = _extractList(response);
    return items.map(_mapReport).toList();
  }

  Future<ReportHiveModel> create({
    required String category,
    required String location,
    required String message,
    String priority = 'Medium',
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final token = _requireAccessToken();
    final safeCategory = category.trim().isEmpty ? 'Other' : category.trim();
    final safeLocation = location.trim();
    final safeMessage = message.trim();
    final safePriority = _mapPriorityToApi(priority);
    final title = _buildTitle(
      category: safeCategory,
      location: safeLocation,
      message: safeMessage,
    );
    final fields = <String, dynamic>{
      'title': title,
      'category': _mapCategoryToApi(safeCategory),
      'priority': safePriority,
    };
    final attachment = _buildAttachmentPayload(
      attachmentBytes: attachmentBytes,
      attachmentName: attachmentName,
    );
    if (attachment != null) {
      fields['attachment'] = attachment;
    }
    final response = await _client.postJson(
      ApiEndpoints.reports,
      fields,
      accessToken: token,
    );
    final payload = _extractItem(response);
    final report = _mapReport(payload, fallbackTitle: title);
    return report.copyWith(
      location: safeLocation.isNotEmpty ? safeLocation : report.location,
      message: safeMessage.isNotEmpty ? safeMessage : report.message,
      category: safeCategory,
    );
  }

  Future<ReportHiveModel> update({
    required String id,
    required String category,
    required String location,
    required String message,
  }) async {
    if (id.trim().isEmpty) {
      throw const ApiException('Report id is required.');
    }
    _buildTitle(category: category, location: location, message: message);
    throw const ApiException(
      'Editing report details is not available yet. Please create a new report instead.',
    );
  }

  Future<ReportHiveModel> updateStatus({
    required String id,
    required String status,
  }) async {
    final token = _requireAccessToken();
    final response = await _client.patchJson(
      '${ApiEndpoints.reports}/$id',
      {
        'status': _mapStatusToApi(status),
      },
      accessToken: token,
    );
    final payload = _extractItem(response);
    return _mapReport(payload);
  }

  Future<void> delete(String id) async {
    final token = _requireAccessToken();
    await _client.deleteJson(
      '${ApiEndpoints.reports}/$id',
      accessToken: token,
    );
  }

  String _requireAccessToken() {
    final token = accessToken?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again to access reports.');
    }
    return token;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'] ??
        response['reports'] ??
        response['items'] ??
        response;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final list = data['reports'] ?? data['items'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _extractItem(Map<String, dynamic> response) {
    final data = response['data'] ?? response['report'] ?? response;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  ReportHiveModel _mapReport(
    Map<String, dynamic> json, {
    String? fallbackTitle,
  }) {
    final mapped = ReportHiveModel.fromJson(json);
    final reporterMap = _extractReporterMap(json);
    final normalizedStatus = _normalizeStatus(mapped.status);
    final title = _safeString(json['title']) ?? fallbackTitle ?? '';
    final parsed = _parseTitle(title);
    final mappedCategory = _mapCategoryFromApi(mapped.category);
    final resolvedCategory = _resolveCategory(
      mappedCategory: mappedCategory,
      parsedCategory: parsed.category,
    );
    final location = mapped.location.trim().isNotEmpty
        ? mapped.location.trim()
        : parsed.location;
    final message = mapped.message.trim().isNotEmpty
        ? mapped.message.trim()
        : parsed.message;
    final reporterId = _extractReporterId(json, reporterMap);
    final reporterName = mapped.reporterName ??
        _safeString(json['createdByName']) ??
        _safeString(json['userName']) ??
        _safeString(
          reporterMap?['name'] ??
              reporterMap?['fullName'] ??
              reporterMap?['email'],
        );
    final reporterPhotoUrl = mapped.reporterPhotoUrl ??
        _safeString(json['createdByPhotoUrl']) ??
        _safeString(json['userPhotoUrl']) ??
        _safeString(
          reporterMap?['profileImageUrl'] ??
              reporterMap?['profilePhotoUrl'] ??
              reporterMap?['photoUrl'] ??
              reporterMap?['avatar'] ??
              reporterMap?['photo'],
        );

    return ReportHiveModel(
      id: mapped.id.trim().isNotEmpty
          ? mapped.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      userId:
          mapped.userId.trim().isNotEmpty ? mapped.userId : (reporterId ?? ''),
      createdAt: mapped.createdAt,
      category: resolvedCategory,
      location: location.isNotEmpty ? location : 'Location shared in details',
      message: message.isNotEmpty ? message : title,
      status: normalizedStatus,
      attachmentUrl: _resolveAttachmentUrl(json, mapped.attachmentUrl),
      reporterName: reporterName,
      reporterPhotoUrl: reporterPhotoUrl,
    );
  }

  String _normalizeStatus(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('progress')) return 'in_progress';
    if (value.contains('resolved') || value.contains('closed')) {
      return 'resolved';
    }
    if (value.contains('open') || value.contains('pending')) return 'pending';
    return 'pending';
  }

  String _mapCategoryToApi(String category) {
    switch (category) {
      case 'Missed Pickup':
        return 'Missed Pickup';
      case 'Overflowing Bin':
        return 'Overflow';
      case 'Payment':
        return 'Payment';
      case 'Garbage Pile':
      case 'Illegal Dumping':
      case 'Blocked Drain':
      case 'Burning Waste':
      case 'Bad Smell':
      case 'Other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  String _mapPriorityToApi(String priority) {
    final value = priority.trim().toLowerCase();
    switch (value) {
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      default:
        return 'Medium';
    }
  }

  String _mapCategoryFromApi(String category) {
    switch (category) {
      case 'Overflow':
        return 'Overflowing Bin';
      case 'Missed Pickup':
        return 'Missed Pickup';
      case 'Payment':
        return 'Payment';
      case 'Other':
        return 'Other';
      default:
        return category;
    }
  }

  String _mapStatusToApi(String status) {
    switch (status) {
      case 'pending':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  String _buildTitle({
    required String category,
    required String location,
    required String message,
  }) {
    final safeCategory = _sanitizeTitlePart(category, fallback: 'Other');
    final safeLocation =
        _sanitizeTitlePart(location, fallback: 'Location not shared');
    final safeMessage = _sanitizeTitlePart(
      message,
      fallback: 'Issue reported from Kachra Alert app.',
    );
    return '$safeCategory$_titleDelimiter$safeLocation$_titleDelimiter$safeMessage';
  }

  Map<String, dynamic>? _buildAttachmentPayload({
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) {
    if (attachmentBytes == null || attachmentBytes.isEmpty) return null;
    final fileName = _sanitizeTitlePart(
      attachmentName ?? 'attachment.jpg',
      fallback: 'attachment.jpg',
    );
    return {
      'name': fileName,
      'mimeType': _mimeTypeFor(fileName),
      'dataBase64': base64Encode(attachmentBytes),
    };
  }

  String _resolveCategory({
    required String mappedCategory,
    required String parsedCategory,
  }) {
    if (mappedCategory.isEmpty || mappedCategory == 'Other') {
      if (parsedCategory.isNotEmpty) return parsedCategory;
      return 'Other';
    }
    return mappedCategory;
  }

  String? _resolveAttachmentUrl(Map<String, dynamic> json, String? fallback) {
    final direct = _safeString(json['attachmentUrl'] ?? json['attachment']);
    if (direct != null) return direct;

    final attachments = json['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final map = first.cast<String, dynamic>();
        final url = _safeString(map['url'] ?? map['attachmentUrl']);
        if (url != null) return url;
      }
    }
    return fallback;
  }

  Map<String, dynamic>? _extractReporterMap(Map<String, dynamic> json) {
    final reporter =
        json['createdBy'] ?? json['user'] ?? json['reporter'] ?? json['author'];
    if (reporter is Map) {
      return reporter.cast<String, dynamic>();
    }
    return null;
  }

  String? _extractReporterId(
    Map<String, dynamic> json,
    Map<String, dynamic>? reporterMap,
  ) {
    final direct = _safeString(
      json['userId'] ?? json['createdById'] ?? json['reporterId'],
    );
    if (direct != null) return direct;

    final nested = _safeString(
      reporterMap?['id'] ?? reporterMap?['_id'] ?? reporterMap?['userId'],
    );
    if (nested != null) return nested;

    final createdBy = json['createdBy'];
    if (createdBy is String) {
      return _safeString(createdBy);
    }
    return null;
  }

  _ParsedTitle _parseTitle(String raw) {
    final title = raw.trim();
    if (title.isEmpty) {
      return const _ParsedTitle(
        category: 'Other',
        location: '',
        message: '',
      );
    }

    final chunks = title.split(_titleDelimiter);
    if (chunks.length >= 3) {
      return _ParsedTitle(
        category: chunks.first.trim(),
        location: chunks[1].trim(),
        message: chunks.sublist(2).join(_titleDelimiter).trim(),
      );
    }

    final oldSplit = title.split(' @ ');
    if (oldSplit.length == 2) {
      return _ParsedTitle(
        category: oldSplit.first.trim(),
        location: oldSplit.last.trim(),
        message: title,
      );
    }

    return _ParsedTitle(
      category: 'Other',
      location: '',
      message: title,
    );
  }

  String _sanitizeTitlePart(
    String value, {
    required String fallback,
  }) {
    final trimmed = value.trim().replaceAll(_titleDelimiter, ' ');
    if (trimmed.isEmpty) return fallback;
    return trimmed;
  }

  String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  String? _safeString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

const _titleDelimiter = '|||';

class _ParsedTitle {
  const _ParsedTitle({
    required this.category,
    required this.location,
    required this.message,
  });

  final String category;
  final String location;
  final String message;
}
