import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/notification.dart';

void main() {
  group('NotificationTest -', () {
    test('fromJson parses when params is null', () {
      final notification = Notification.fromJson({
        'id': '11',
        'type': 'notification',
        'attributes': {
          'recipient_type': 'User',
          'recipient_id': 7,
          'type': 'starred_project',
          'read_at': null,
          'created_at': '2024-01-01T10:00:00Z',
          'updated_at': '2024-01-01T11:00:00Z',
          'params': null,
          'unread': true,
        },
      });

      expect(notification.id, '11');
      expect(notification.attributes.params, isNull);
      expect(notification.attributes.unread, isTrue);
    });

    test('fromJson parses when params has user and project', () {
      final notification = Notification.fromJson({
        'id': '12',
        'type': 'notification',
        'attributes': {
          'recipient_type': 'User',
          'recipient_id': 7,
          'type': 'forked_project',
          'read_at': null,
          'created_at': '2024-01-01T10:00:00Z',
          'updated_at': '2024-01-01T11:00:00Z',
          'params': {
            'user': {
              'id': 1,
              'name': 'Test User',
              'email': 'test@example.com',
              'subscribed': false,
              'admin': false,
              'country': null,
              'profile_picture': null,
              'educational_institute': null,
            },
            'project': {
              'id': 2,
              'author_id': 1,
              'project_access_type': 'public',
              'name': 'Test Project',
              'project_submission': false,
              'description': 'Desc',
              'slug': 'test-project',
              'view': 3,
              'image_preview': null,
              'created_at': null,
              'updated_at': null,
            },
          },
          'unread': false,
        },
      });

      expect(notification.attributes.params, isNotNull);
      expect(
        notification.attributes.params?.user?.data.attributes.name,
        'Test User',
      );
      expect(notification.attributes.params?.project?.name, 'Test Project');
    });

    test('NotificationParams.fromJson handles partial params', () {
      final params = NotificationParams.fromJson({
        'user': {
          'id': 1,
          'name': 'Only User',
          'email': 'test@example.com',
          'subscribed': false,
          'admin': false,
          'country': null,
          'profile_picture': null,
          'educational_institute': null,
        },
      });

      expect(params.user, isNotNull);
      expect(params.project, isNull);
      expect(params.user?.data.attributes.name, 'Only User');
    });
  });
}
