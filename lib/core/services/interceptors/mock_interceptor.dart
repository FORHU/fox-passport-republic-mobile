import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';

/// Serves canned responses so the template runs with **no backend**.
///
/// Added to Dio only when `AppConfig.instance.useMock` is true. Because it
/// lives in the Dio pipeline, the real `ApiService` code path is still fully
/// exercised — set `USE_MOCK=false` once your backend is ready and nothing
/// else has to change.
class MockInterceptor extends Interceptor {
  static const Duration _latency = Duration(milliseconds: 600);

  final _mockConversations = <Map<String, dynamic>>[
    {
      'id': 'mock-conversation-1',
      'isGroup': false,
      'isInbox': false,
      'otherUser': {
        'id': '2',
        'name': 'Rico Rival',
        'imgId': null,
        'roleType': ['eventFoxer'],
        'identityVerifiedAt': '2026-01-01T00:00:00.000Z',
        'isOnline': true,
      },
      'contextType': 'booking',
      'contextLabel': 'Sky Hall · Sat 17 Oct',
      'lastMessageAt': '2026-10-13T06:02:00.000Z',
      'createdAt': '2026-10-12T06:00:00.000Z',
      'unreadCount': 2,
      'status': 'accepted',
      'isIncomingRequest': false,
      'lastMessage': {
        'content': 'Perfect, thank you',
        'isMine': true,
      },
      'isMuted': false,
      'isPinned': false,
      'pinnedAt': null,
    },
    {
      'id': 'mock-conversation-2',
      'isGroup': false,
      'isInbox': true,
      'inbox': {
        'type': 'venue',
        'id': 'mock-venue-1',
        'name': 'Sky Hall',
      },
      'otherUser': null,
      'contextType': null,
      'contextLabel': 'Venue inbox',
      'lastMessageAt': '2026-10-13T05:00:00.000Z',
      'createdAt': '2026-10-12T05:00:00.000Z',
      'unreadCount': 0,
      'status': 'accepted',
      'isIncomingRequest': false,
      'lastMessage': {'content': 'Is parking included?', 'isMine': true},
      'isMuted': false,
      'isPinned': false,
      'pinnedAt': null,
    },
    {
      'id': 'mock-conversation-3',
      'isGroup': true,
      'name': 'Sample group',
      'otherUser': null,
      'contextType': null,
      'contextLabel': null,
      'lastMessageAt': '2026-10-11T08:00:00.000Z',
      'createdAt': '2026-10-10T08:00:00.000Z',
      'unreadCount': 0,
      'status': 'accepted',
      'isIncomingRequest': false,
      'lastMessage': {
        'content': 'Sample: final headcount is 40',
        'isMine': false,
      },
      'isMuted': false,
      'isPinned': true,
      'pinnedAt': '2026-10-12T08:00:00.000Z',
    },
    {
      'id': 'mock-conversation-4',
      'isGroup': false,
      'isInbox': false,
      'otherUser': {
        'id': '3',
        'name': 'Sample Foxer',
        'imgId': null,
        'roleType': ['eventFoxer'],
        'identityVerifiedAt': null,
      },
      'contextType': null,
      'contextLabel': null,
      'lastMessageAt': '2026-10-12T04:00:00.000Z',
      'createdAt': '2026-10-12T04:00:00.000Z',
      'unreadCount': 0,
      'status': 'pending',
      'isIncomingRequest': true,
      'lastMessage': {'content': 'Sent a photo', 'isMine': false},
      'isMuted': true,
      'isPinned': false,
      'pinnedAt': null,
    },
  ];

  final _mockMessages = <Map<String, dynamic>>[
    {
      'id': 'mock-message-1',
      'conversationId': 'mock-conversation-1',
      'senderId': '2',
      'content': "Hi, I'm coordinating your night at Sky Hall.",
      'readAt': null,
      'createdAt': '2026-10-13T05:50:00.000Z',
      'attachmentUrls': <String>[],
    },
    {
      'id': 'mock-message-2',
      'conversationId': 'mock-conversation-1',
      'senderId': '1',
      'content': 'Great. Can we add a photographer?',
      'readAt': null,
      'createdAt': '2026-10-13T05:52:00.000Z',
      'attachmentUrls': <String>[],
    },
    {
      'id': 'mock-message-3',
      'conversationId': 'mock-conversation-1',
      'senderId': '2',
      'content': "Yes, I'll send two options tonight.",
      'readAt': null,
      'createdAt': '2026-10-13T05:54:00.000Z',
      'attachmentUrls': <String>[],
      'replyTo': {'content': 'Can we add a photographer?'},
      'reactions': [
        {'emoji': '👍', 'count': 1},
      ],
    },
    {
      'id': 'mock-message-4',
      'conversationId': 'mock-conversation-1',
      'senderId': '2',
      'content': 'Sound check is at 5, see you there',
      'readAt': null,
      'createdAt': '2026-10-13T06:00:00.000Z',
      'attachmentUrls': <String>[],
    },
    {
      'id': 'mock-message-5',
      'conversationId': 'mock-conversation-1',
      'senderId': '1',
      'content': 'Perfect, thank you',
      'readAt': '2026-10-13T06:03:00.000Z',
      'createdAt': '2026-10-13T06:02:00.000Z',
      'attachmentUrls': <String>[],
    },
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(_latency);
    final path = options.path;
    final body = _asMap(options.data);

    if (path == ApiEndpoints.locationCountries) {
      handler.resolve(
        _ok(options, {
          'data': [
            {'code': 'PH', 'name': 'Philippines'},
            {'code': 'US', 'name': 'United States'},
            {'code': 'GB', 'name': 'United Kingdom'},
          ],
        }),
      );
      return;
    }

    final locationPath =
        RegExp(r'^/locations/countries/([A-Z]{2})/(states|cities)$')
            .firstMatch(path);
    if (locationPath != null) {
      final countryCode = locationPath.group(1);
      final resource = locationPath.group(2);
      if (resource == 'states') {
        handler.resolve(
          _ok(options, {
            'data': switch (countryCode) {
              'PH' => [
                  {'code': 'NCR', 'name': 'Metro Manila'},
                  {'code': 'CEB', 'name': 'Central Visayas'},
                ],
              'US' => [
                  {'code': 'CA', 'name': 'California'},
                  {'code': 'NY', 'name': 'New York'},
                ],
              'GB' => [
                  {'code': 'ENG', 'name': 'England'},
                  {'code': 'SCT', 'name': 'Scotland'},
                ],
              _ => <Map<String, String>>[],
            },
          }),
        );
        return;
      }

      final region = options.queryParameters['state'];
      handler.resolve(
        _ok(options, {
          'data': switch ((countryCode, region)) {
            ('PH', 'NCR') => ['Manila', 'Quezon City', 'Makati'],
            ('PH', 'CEB') => ['Cebu City', 'Lapu-Lapu City', 'Mandaue'],
            ('US', 'CA') => ['Los Angeles', 'San Francisco', 'San Diego'],
            ('US', 'NY') => ['New York City', 'Buffalo', 'Rochester'],
            ('GB', 'ENG') => ['London', 'Manchester', 'Birmingham'],
            ('GB', 'SCT') => ['Edinburgh', 'Glasgow', 'Aberdeen'],
            ('PH', null) => ['Manila', 'Cebu City', 'Davao City'],
            ('US', null) => ['New York City', 'Los Angeles', 'Chicago'],
            ('GB', null) => ['London', 'Manchester', 'Birmingham'],
            _ => <String>[],
          },
        }),
      );
      return;
    }

    // Lists the new screens ask for that the mock has no rows for. Answering
    // them with an empty list keeps the screens on their sample content
    // without a rejected request (which debuggers pause on).
    if (path.startsWith('/bookings/user/')) {
      handler.resolve(_ok(options, {'data': <Map<String, dynamic>>[]}));
      return;
    }

    if (path == ApiEndpoints.feed && options.method == 'GET') {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': [
            {
              'id': 'p1',
              'content': 'Just wrapped our team offsite at a garden venue in '
                  'Davao. The staff made it effortless.',
              'tab': 'community',
              'createdAt': DateTime.now()
                  .subtract(const Duration(hours: 3))
                  .toUtc()
                  .toIso8601String(),
              'likesCount': 12,
              'commentsCount': 2,
              'isLikedByMe': false,
              'author': {'id': 'u1', 'name': 'Maria S.'},
            },
            {
              'id': 'p2',
              'content': 'Looking for a sound system for a 100-guest '
                  'birthday this month. Any recommendations?',
              'tab': 'community',
              'createdAt': DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toUtc()
                  .toIso8601String(),
              'likesCount': 4,
              'commentsCount': 0,
              'isLikedByMe': true,
              'author': {'id': 'u2', 'name': 'Jon D.'},
            },
          ],
          'nextCursor': null,
        }),
      );
      return;
    }

    if (RegExp(r'^/feed/[^/]+/comments$').hasMatch(path) &&
        options.method == 'GET') {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': [
            {
              'id': 'c1',
              'content': 'Congrats! Which venue was it?',
              'createdAt': DateTime.now()
                  .subtract(const Duration(hours: 2))
                  .toUtc()
                  .toIso8601String(),
              'author': {'id': 'u2', 'name': 'Jon D.'},
              'replies': <Object>[],
            },
          ],
        }),
      );
      return;
    }

    if (path == ApiEndpoints.feed ||
        RegExp(r'^/feed/[^/]+/(reaction|comments)$').hasMatch(path)) {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {'id': 'new'},
        }),
      );
      return;
    }

    // One venue, so the detail page has something to show in mock mode.
    final venueMatch = RegExp(r'^/venues/([^/]+)$').firstMatch(path);
    if (venueMatch != null && options.method == 'GET') {
      handler.resolve(
        _ok(options, {
          'venue': {
            'id': venueMatch.group(1),
            'name': 'Sky Hall',
            'description': 'A bright hall with a garden terrace, a stage '
                'and a full sound system.',
            'category': 'indoor',
            'address': '12 Roxas Avenue',
            'city': 'Davao City',
            'country': 'Philippines',
            'capacity': 120,
            'price': '15000',
            'billingRate': 'daily',
            'images': <Object>[],
            'spaceType': ['indoor'],
            'amenities': ['Air conditioning', 'Parking'],
            'policies': ['No smoking indoors', 'Music off by 11 pm'],
          },
        }),
      );
      return;
    }

    if (path.startsWith('/reviews/listing/')) {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {
            'reviews': [
              {
                'id': 'r1',
                'rating': 5,
                'comment': 'Beautiful space and a very helpful host.',
                'createdAt': '2026-09-12T10:00:00.000Z',
                'user': {'id': 'u1', 'name': 'Maria S.'},
                'replies': [
                  {
                    'text': 'Thank you, Maria! Come again.',
                    'user': {'name': 'Host'},
                  },
                ],
              },
              {
                'id': 'r2',
                'rating': 4,
                'comment': 'Great for our team event.',
                'createdAt': '2026-08-02T10:00:00.000Z',
                'user': {'id': 'u2', 'name': 'Jon D.'},
                'replies': <Object>[],
              },
            ],
            'ratingDistribution': {
              '5': '50%',
              '4': '50%',
              '3': '0%',
              '2': '0%',
              '1': '0%',
            },
          },
        }),
      );
      return;
    }

    if (path == ApiEndpoints.reviewsCreate) {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {'id': 'r-new'},
        }),
      );
      return;
    }

    if (path == ApiEndpoints.notifications) {
      handler.resolve(
        _ok(options, {
          'success': true,
          'notifications': <Map<String, dynamic>>[],
          'unreadCount': 0,
        }),
      );
      return;
    }

    if (path == ApiEndpoints.notificationsReadAll ||
        RegExp(r'^/notifications/[^/]+/read$').hasMatch(path)) {
      handler.resolve(_ok(options, {'success': true}));
      return;
    }

    if (path == ApiEndpoints.conversations && options.method == 'GET') {
      handler
          .resolve(_ok(options, {'success': true, 'data': _mockConversations}));
      return;
    }

    final cancelPath =
        RegExp(r'^/bookings/([^/]+)/cancel(/check)?$').firstMatch(path);
    if (cancelPath != null && options.method == 'POST') {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': cancelPath.group(2) != null
              ? {
                  'eligible': true,
                  'refundPercent': 100,
                  'totalPaid': 26250,
                  'estimatedRefund': 26250,
                  'message': 'Free cancellation for 48 hours.',
                  'hoursUntilStart': 120,
                }
              : {
                  'booking': {'id': cancelPath.group(1)},
                  'refunds': <Object>[],
                },
        }),
      );
      return;
    }

    final foxerPath = RegExp(r'^/users/foxers/([^/]+)$').firstMatch(path);
    if (foxerPath != null && options.method == 'GET') {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {
            'id': foxerPath.group(1),
            'name': 'Rico Rival',
            'imgId': null,
            'city': 'Davao City',
            'roleType': ['eventFoxer'],
            'identityVerifiedAt': '2026-01-01T00:00:00.000Z',
            'avgRating': 4.8,
            'reviewCount': 12,
            'services': <Object>[],
            'assets': <Object>[],
            'venues': <Object>[],
            'eventTemplates': <Object>[],
          },
        }),
      );
      return;
    }

    if (path == ApiEndpoints.matchesMine && options.method == 'GET') {
      Map<String, dynamic> row(
        String id,
        String style,
        String requestStatus,
        String status,
        num total,
      ) =>
          {
            'id': id,
            'status': status,
            'guestCount': 40,
            'totalAmount': total,
            'startAt': DateTime.now()
                .add(const Duration(days: 20))
                .toUtc()
                .toIso8601String(),
            'payments': <Object>[],
            'event': {
              'id': 'e-$id',
              'name': 'Match with $style',
              'requestStatus': requestStatus,
              'host': {'id': '2', 'name': 'Rico Rival'},
            },
          };
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': [
            row('m1', 'Garden Birthday', 'pending', 'pending', 0),
            row('m2', 'Own idea', 'approved', 'pending', 18000),
            row('m3', 'Rooftop Launch', 'rejected', 'cancelled', 0),
          ],
        }),
      );
      return;
    }

    if (path == ApiEndpoints.matches && options.method == 'POST') {
      handler.resolve(
        _ok(options, {
          'message': 'Match request created',
          'bookingId': 'mock-booking-match',
          'clientSecret': null,
        }),
      );
      return;
    }

    if (path == ApiEndpoints.fxRates) {
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {
            'base': 'PHP',
            'rates': {
              'PHP': 1,
              'USD': 0.0176,
              'EUR': 0.0162,
              'GBP': 0.0139,
              'JPY': 2.63,
            },
            'currencies': ['PHP', 'USD', 'EUR', 'GBP', 'JPY'],
          },
        }),
      );
      return;
    }

    if (path == ApiEndpoints.uploadFile && options.method == 'POST') {
      handler.resolve(
        _ok(options, {
          'file': {'url': 'https://placehold.co/600x400/png'},
        }),
      );
      return;
    }

    // Start a chat with a user or a venue inbox: reuse the mock one if there
    // is one for that target, otherwise open an empty one.
    if ((path == ApiEndpoints.conversations ||
            path == ApiEndpoints.conversationsInbox) &&
        options.method == 'POST') {
      final isInbox = path == ApiEndpoints.conversationsInbox;
      final target =
          (isInbox ? body['venueId'] : body['otherUserId'])?.toString();
      final existing = _mockConversations.where((c) {
        final other = isInbox ? c['inbox'] : c['otherUser'];
        return other is Map && other['id'].toString() == target;
      });
      var id = existing.isEmpty ? null : existing.first['id'];
      if (id == null) {
        id = 'mock-conversation-${_mockConversations.length + 1}';
        _mockConversations.add({
          'id': id,
          'isGroup': false,
          'isInbox': isInbox,
          if (isInbox)
            'inbox': {'type': 'venue', 'id': target, 'name': 'Venue'}
          else
            'otherUser': {
              'id': target,
              'name': 'Foxer',
              'roleType': <String>[],
            },
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'unreadCount': 0,
          'status': 'accepted',
          'isIncomingRequest': false,
          'isMuted': false,
          'isPinned': false,
        });
      }
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {'id': id},
        }),
      );
      return;
    }

    final messagePath = RegExp(
      r'^/conversations/([^/]+)/messages/([^/]+)(/reaction)?$',
    ).firstMatch(path);
    if (messagePath != null) {
      final index =
          _mockMessages.indexWhere((m) => m['id'] == messagePath.group(2));
      if (index != -1) {
        final message = _mockMessages[index];
        if (messagePath.group(3) != null) {
          final emoji = body['emoji'] as String?;
          message['reactions'] = emoji == null
              ? <Map<String, dynamic>>[]
              : [
                  {'emoji': emoji, 'count': 1},
                ];
        } else if (options.method == 'PATCH') {
          message['content'] = body['content'];
          message['editedAt'] = DateTime.now().toUtc().toIso8601String();
        } else if (options.method == 'DELETE') {
          _mockMessages.removeAt(index);
        }
      }
      handler.resolve(_ok(options, {'success': true}));
      return;
    }

    final flagPath =
        RegExp(r'^/conversations/([^/]+)/(mute|pin)$').firstMatch(path);
    if (flagPath != null && options.method == 'PATCH') {
      for (final c in _mockConversations) {
        if (c['id'] == flagPath.group(1)) {
          if (flagPath.group(2) == 'mute') c['isMuted'] = body['muted'] == true;
          if (flagPath.group(2) == 'pin') {
            c['isPinned'] = body['pinned'] == true;
          }
        }
      }
      handler.resolve(_ok(options, {'success': true}));
      return;
    }

    final messagesPath =
        RegExp(r'^/conversations/([^/]+)/messages$').firstMatch(path);
    if (messagesPath != null) {
      if (options.method == 'GET') {
        handler.resolve(
          _ok(options, {
            'success': true,
            'data': _mockMessages
                .where(
                  (message) =>
                      message['conversationId'] == messagesPath.group(1),
                )
                .toList(growable: false),
          }),
        );
        return;
      }
      if (options.method == 'POST') {
        final content = body['content'] as String? ?? '';
        final now = DateTime.now().toUtc().toIso8601String();
        final message = <String, dynamic>{
          'id': 'mock-message-${_mockMessages.length + 1}',
          'conversationId': messagesPath.group(1),
          'senderId': '1',
          'content': content,
          'readAt': null,
          'createdAt': now,
          'attachmentUrls': body['attachmentUrls'] ?? <String>[],
          if (body['replyToId'] != null) 'replyToId': body['replyToId'],
        };
        _mockMessages.add(message);
        for (final conversation in _mockConversations) {
          if (conversation['id'] == messagesPath.group(1)) {
            conversation['lastMessageAt'] = now;
            conversation['lastMessage'] = {'content': content, 'isMine': true};
          }
        }
        handler.resolve(_ok(options, {'success': true, 'data': message}));
        return;
      }
    }

    final readPath = RegExp(r'^/conversations/([^/]+)/read$').firstMatch(path);
    if (readPath != null && options.method == 'PATCH') {
      for (final conversation in _mockConversations) {
        if (conversation['id'] == readPath.group(1)) {
          conversation['unreadCount'] = 0;
        }
      }
      handler.resolve(_ok(options, {'success': true}));
      return;
    }

    final requestPath =
        RegExp(r'^/conversations/([^/]+)/(accept|decline)$').firstMatch(path);
    if (requestPath != null && options.method == 'POST') {
      final conversationId = requestPath.group(1);
      final action = requestPath.group(2);
      if (action == 'decline') {
        _mockConversations.removeWhere(
          (conversation) => conversation['id'] == conversationId,
        );
      } else {
        for (final conversation in _mockConversations) {
          if (conversation['id'] == conversationId) {
            conversation['status'] = 'accepted';
            conversation['isIncomingRequest'] = false;
          }
        }
      }
      handler.resolve(
        _ok(options, {
          'success': true,
          'data': {'status': action == 'accept' ? 'accepted' : 'declined'},
        }),
      );
      return;
    }

    switch (path) {
      case ApiEndpoints.login:
        final email = (body['email'] as String? ?? '').trim();
        final password = body['password'] as String? ?? '';
        if (password.length < 6) {
          handler.reject(
            _error(options, 401, 'Invalid email or password'),
          );
          return;
        }
        handler.resolve(
          _ok(options, {
            'id': '1',
            'email': email,
            'name': email.split('@').first,
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
          }),
        );
      case ApiEndpoints.refresh:
        handler.resolve(
          _ok(options, {
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
          }),
        );
      case ApiEndpoints.logout:
        handler.resolve(_ok(options, {'success': true}));
      case ApiEndpoints.me:
        if (options.method == 'PUT') {
          handler.resolve(_ok(options, {'success': true}));
        } else {
          // Shape satisfies auth, profile, and onboarding data sources.
          handler.resolve(
            _ok(options, {
              'id': '1',
              'email': 'ada@example.com',
              'name': 'Ada Lovelace',
              'country': '',
              'state': '',
              'city': '',
              'district': '',
              'roleType': <String>[],
              'token': 'mock-access-token',
              'refreshToken': 'mock-refresh-token',
              'bio': 'Building great things with Flutter.',
              'joinedAt': '2024-01-15T00:00:00.000Z',
            }),
          );
        }
      case ApiEndpoints.roleRequestsMine:
        handler.resolve(_ok(options, {'data': <Map<String, dynamic>>[]}));
      case ApiEndpoints.users:
        handler.resolve(
          _ok(options, {
            'data': [
              {'id': '1', 'name': 'Ada Lovelace'},
              {'id': '2', 'name': 'Alan Turing'},
              {'id': '3', 'name': 'Grace Hopper'},
            ],
          }),
        );
      // Public browse data, so the Home hero's globe has pins and cards (and
      // the Home feed has items) with no backend. Same shapes as the real API:
      // events are `{ data: [...] }`, venues are `{ venues: [...] }`.
      case ApiEndpoints.categories:
        Map<String, dynamic> category(
          String name,
          int count, {
          bool event = false,
          int venues = 0,
          int services = 0,
          int assets = 0,
        }) =>
            {
              'name': name,
              'count': count,
              'isEventCategory': event,
              'sources': {
                'venues': venues,
                'services': services,
                'assets': assets,
                'events': event ? count : 0,
              },
            };
        handler.resolve(
          _ok(options, {
            'success': true,
            'data': [
              category('birthday', 34, event: true),
              category('wedding', 28, event: true),
              category('corporate', 19, event: true),
              category('social', 12, event: true),
              category('other', 7, event: true),
              category('photography', 15, services: 15),
              category('dj', 9, services: 9),
              category('catering', 6, services: 6),
              category('sound_system', 11, assets: 11),
              category('garden', 5, venues: 5),
              category('indoor', 8, venues: 8),
            ],
          }),
        );
      case ApiEndpoints.calendar:
        final today = DateTime.now();
        DateTime at(int days, int hour) =>
            DateTime(today.year, today.month, today.day + days, hour);
        handler.resolve(
          _ok(options, {
            'success': true,
            'data': [
              {
                'id': 'booking:mock-1',
                'kind': 'event',
                'role': 'guest',
                'title': 'Rooftop Launch Night',
                'start': at(2, 19).toUtc().toIso8601String(),
                'end': at(2, 23).toUtc().toIso8601String(),
                'status': 'confirmed',
              },
              {
                'id': 'event:mock-2',
                'kind': 'event',
                'role': 'host',
                'title': 'Garden Birthday',
                'start': at(5, 14).toUtc().toIso8601String(),
                'end': at(5, 20).toUtc().toIso8601String(),
                'status': 'approved',
              },
            ],
          }),
        );
      case ApiEndpoints.eventsBrowse:
        handler.resolve(_ok(options, {'data': _mockEvents}));
      case ApiEndpoints.publicEventsBrowse:
        final now = DateTime.now().toUtc();
        handler.resolve(
          _ok(options, {
            'success': true,
            'data': [
              {
                'id': 'mock-public-event-1',
                'name': 'Manila Night Market',
                'eventCategory': 'social',
                'startAt': now.add(const Duration(days: 7)).toIso8601String(),
                'endAt': now
                    .add(const Duration(days: 7, hours: 5))
                    .toIso8601String(),
                'guestCount': 120,
                'totalAmount': 18000,
                'targetCity': 'Manila',
              },
              {
                'id': 'mock-public-event-2',
                'name': 'Cebu Food Fest',
                'eventCategory': 'social',
                'startAt': now.add(const Duration(days: 21)).toIso8601String(),
                'endAt': now
                    .add(const Duration(days: 21, hours: 6))
                    .toIso8601String(),
                'guestCount': 250,
                'totalAmount': 32000,
                'targetCity': 'Cebu City',
              },
            ],
            'pagination': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1},
          }),
        );
      case ApiEndpoints.venues:
        handler.resolve(_ok(options, {'venues': <Map<String, dynamic>>[]}));
      // Nothing booked and a blank passport: the screens then show their
      // sample content, so a demo run has something to look at.
      case ApiEndpoints.foxers:
      case ApiEndpoints.assetsBrowse:
      case ApiEndpoints.servicesBrowse:
        handler.resolve(_ok(options, {'data': <Map<String, dynamic>>[]}));
      case ApiEndpoints.bookingsUpcoming:
        handler.resolve(_ok(options, {'data': <Map<String, dynamic>>[]}));
      case ApiEndpoints.passportMe:
        handler.resolve(
          _ok(options, {
            'data': {
              'paths': <Object>[],
              'stamps': <Object>[],
              'userBadges': <Object>[],
            },
          }),
        );
      case ApiEndpoints.passportBadges:
        handler.resolve(_ok(options, {'data': <Map<String, dynamic>>[]}));
      default:
        handler.reject(_error(options, 404, 'Unknown endpoint: $path'));
    }
  }

  static const List<Map<String, Object?>> _mockEvents = [
    {
      'id': 'mock-manila-1',
      'name': 'Debut Manila',
      'category': 'birthday',
      'targetCity': 'Manila',
      'targetCountry': 'Philippines',
      'lat': 14.5995,
      'lng': 120.9842,
      'images': [
        {
          'url':
              'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=200&auto=format&fit=crop',
        },
      ],
    },
    {
      'id': 'mock-manila-2',
      'name': 'Rooftop Launch Night',
      'category': 'corporate',
      'targetCity': 'Manila',
      'targetCountry': 'Philippines',
      'lat': 14.5547,
      'lng': 121.0244,
    },
    {
      'id': 'mock-cebu-1',
      'name': 'Food Festival Cebu',
      'category': 'social',
      'targetCity': 'Cebu City',
      'targetCountry': 'Philippines',
      'lat': 10.3157,
      'lng': 123.8854,
    },
    {
      'id': 'mock-cebu-2',
      'name': 'Beachfront Wedding',
      'category': 'wedding',
      'targetCity': 'Cebu City',
      'targetCountry': 'Philippines',
      'lat': 10.3157,
      'lng': 123.8854,
    },
    {
      'id': 'mock-baguio-1',
      'name': 'Mountain Wedding Baguio',
      'category': 'wedding',
      'targetCity': 'Baguio',
      'targetCountry': 'Philippines',
      'lat': 16.4023,
      'lng': 120.5960,
    },
    {
      'id': 'mock-boracay-1',
      'name': 'Sunset Beach Party',
      'category': 'social',
      'targetCity': 'Boracay',
      'targetCountry': 'Philippines',
      'lat': 11.9674,
      'lng': 121.9248,
    },
  ];

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  Response<dynamic> _ok(RequestOptions options, Map<String, dynamic> data) =>
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: data,
      );

  DioException _error(RequestOptions options, int status, String message) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: {'message': message},
        ),
      );
}
