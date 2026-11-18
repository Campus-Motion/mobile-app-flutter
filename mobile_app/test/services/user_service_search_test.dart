import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/mock_data_service.dart';
import 'package:mobile_app/services/user_service.dart';

void main() {
  setUp(() => ApiService.mockMode = true);
  tearDown(() => ApiService.mockMode = false);

  group('UserService.searchUsers', () {
    test('matches the username prefix in any case', () async {
      for (final query in ['ca', 'CA', 'Camille']) {
        final users = await UserService().searchUsers(query);
        expect(users.map((u) => u.username), ['Camille.B']);
      }
    });

    test('returns an empty list when nothing matches', () async {
      expect(await UserService().searchUsers('zz'), isEmpty);
    });

    test('returns public fields only (no email)', () async {
      final res = MockDataService().handleGet('/users/search?q=ma');
      expect(res.body, contains('Marc.V'));
      expect(res.body, isNot(contains('email')));
    });

    test('throws on a query the API rejects', () async {
      expect(UserService().searchUsers('a'), throwsException);
    });
  });
}
