import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/utils/media_url.dart';

void main() {
  group('resolveMediaUrl', () {
    test('returns null for empty values', () {
      expect(resolveMediaUrl('https://api.example.com', null), isNull);
      expect(resolveMediaUrl('https://api.example.com', ''), isNull);
      expect(resolveMediaUrl('https://api.example.com', '   '), isNull);
    });

    test('returns absolute URLs unchanged', () {
      expect(
        resolveMediaUrl('https://api.example.com', 'https://cdn.example.com/photo.jpg'),
        'https://cdn.example.com/photo.jpg',
      );
    });

    test('combines base URL with relative path', () {
      expect(
        resolveMediaUrl('https://api.example.com/', 'uploads/photo.jpg'),
        'https://api.example.com/uploads/photo.jpg',
      );
      expect(
        resolveMediaUrl('https://api.example.com', '/uploads/photo.jpg'),
        'https://api.example.com/uploads/photo.jpg',
      );
    });
  });
}
