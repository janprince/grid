import 'package:flutter_test/flutter_test.dart';
import 'package:grid/core/models/models.dart';

void main() {
  const home = Property(
    id: 'p1',
    nickname: 'Home',
    area: 'East Legon',
    city: 'Accra',
    address: '12 Lagos Avenue',
    latitude: 5.6362,
    longitude: -0.1583,
  );

  test('editing a home keeps where it is', () {
    final renamed = home.copyWith(nickname: 'Family house');
    expect(renamed.latitude, 5.6362);
    expect(renamed.longitude, -0.1583);
  });

  test('moving a home to another area drops the old point', () {
    final moved = home.copyWith(area: 'Labone');
    expect(moved.latitude, isNull);
    expect(moved.longitude, isNull);
  });
}
