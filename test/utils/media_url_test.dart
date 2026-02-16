import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/core/utils/media_url.dart';

void main() {
  group('resolveMediaUrl', () {
    test('returns null for null raw value', () {
      expect(resolveMediaUrl('https://api.example.com', null), isNull);
    });

    test('returns null for empty raw value', () {
      expect(resolveMediaUrl('https://api.example.com', ''), isNull);
    });

    test('returns null for whitespace-only raw value', () {
      expect(resolveMediaUrl('https://api.example.com', '   '), isNull);
    });

    test('returns absolute https URL unchanged', () {
      expect(
        resolveMediaUrl(
          'https://api.example.com',
          'https://cdn.example.com/photo.jpg',
        ),
        'https://cdn.example.com/photo.jpg',
      );
    });

    test('joins base URL and relative path correctly', () {
      expect(
        resolveMediaUrl('https://api.example.com/', 'uploads/photo.jpg'),
        'https://api.example.com/uploads/photo.jpg',
      );
    });
  });
}
