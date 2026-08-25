import 'package:flutter_test/flutter_test.dart';
import 'package:there_you_are/services/api_service.dart';

void main() {
  group('User Model Tests', () {
    test('User.fromJson parses full user data correctly', () {
      final json = {
        'id': 1,
        'name': 'Somchai Jaidee',
        'email': 'somchai@example.com',
        'isVerified': true,
        'avatarUrl': 'https://example.com/avatar.jpg',
      };

      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.name, 'Somchai Jaidee');
      expect(user.email, 'somchai@example.com');
      expect(user.isVerified, true);
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('User.fromJson handles fname / lname fallback', () {
      final json = {
        'id': 2,
        'fname': 'Nattapon',
        'lname': 'Boonnara',
        'email': 'nattapon@example.com',
        'is_verified': true,
        'profileImage': 'https://example.com/profile.png',
      };

      final user = User.fromJson(json);
      expect(user.name, 'Nattapon Boonnara');
      expect(user.isVerified, true);
      expect(user.avatarUrl, 'https://example.com/profile.png');
    });
  });

  group('CheckIn Model Tests', () {
    test('CheckIn.fromJson parses checkin with user and coordinates', () {
      final json = {
        'id': 101,
        'lat': 15.1187,
        'lng': 104.3040,
        'locationName': 'มหาวิทยาลัยราชภัฏศรีสะเกษ',
        'address': 'ต.โพธิ์ อ.เมือง จ.ศรีสะเกษ',
        'accuracy': 12.5,
        'description': 'เช็คอิน ณ มรภ.ศรีสะเกษ',
        'imageUrl': 'https://example.com/sskru.jpg',
        'createdAt': '2026-08-25T10:30:00Z',
        'user': {
          'id': 1,
          'name': 'Somchai',
          'profileImage': 'https://example.com/avatar.png',
        },
      };

      final checkIn = CheckIn.fromJson(json);
      expect(checkIn.id, 101);
      expect(checkIn.lat, 15.1187);
      expect(checkIn.lng, 104.3040);
      expect(checkIn.locationName, 'มหาวิทยาลัยราชภัฏศรีสะเกษ');
      expect(checkIn.accuracy, 12.5);
      expect(checkIn.user?.name, 'Somchai');
      expect(checkIn.createdAt, isNotNull);
    });

    test('CheckIn.fromJson handles string coordinates and missing fields gracefully', () {
      final json = {
        'id': '202',
        'lat': '15.123456',
        'lng': '104.345678',
        'accuracy': '5.0',
      };

      final checkIn = CheckIn.fromJson(json);
      expect(checkIn.id, 202);
      expect(checkIn.lat, closeTo(15.123456, 0.000001));
      expect(checkIn.lng, closeTo(104.345678, 0.000001));
      expect(checkIn.accuracy, 5.0);
      expect(checkIn.locationName, isNull);
      expect(checkIn.user, isNull);
    });
  });

  group('Sisaket Coordinates & Constants Tests', () {
    test('Sisaket Rajabhat University coordinates are within expected geographic bounds', () {
      const sskruLat = 15.1187;
      const sskruLng = 104.3040;

      // Sisaket province bounds: Lat approx 14.5 - 15.5, Lng approx 104.0 - 105.0
      expect(sskruLat, greaterThan(14.5));
      expect(sskruLat, lessThan(15.5));
      expect(sskruLng, greaterThan(104.0));
      expect(sskruLng, lessThan(105.0));
    });
  });
}
