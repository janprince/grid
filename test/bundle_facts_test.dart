import 'package:flutter_test/flutter_test.dart';
import 'package:grid/core/models/models.dart';
import 'package:grid/features/payments/widgets/bundle_grid.dart';

BundleFacts _facts(String label, [String value = 'x']) =>
    BundleFacts.of(BillBundle(value: value, label: label, amount: 1));

void main() {
  test('Telecel codes and bracketed prices are not shown', () {
    final f = _facts(
      'No Expiry - 22.29MB (GHs 0.5) · DATANVSTRDLY',
      'DATANVSTRDLY',
    );
    expect(f.size, '22.29MB');
    expect(f.name, 'No Expiry');
    expect(f.group, 'No expiry');
    expect(f.summary, '22.29MB · No Expiry');
  });

  test('an already clean Telecel label reads the same', () {
    final f = _facts('No Expiry - 10.27GB', 'DATANVDBDL4');
    expect(f.size, '10.27GB');
    expect(f.name, 'No Expiry');
  });

  test('MTN names keep their words and lose the stray space', () {
    final f = _facts('460.11MB Kokrokoo , 5am to 8am', 'kokrokoo');
    expect(f.size, '460.11MB');
    expect(f.name, 'Kokrokoo, 5am to 8am');
  });

  test('a size-only bundle has no name', () {
    final f = _facts('406.89MB', '406.89MB');
    expect(f.size, '406.89MB');
    expect(f.name, isEmpty);
    expect(f.summary, '406.89MB');
  });
}
