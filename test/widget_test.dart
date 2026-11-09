import 'package:activity14_fcm/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supported promo payload selects the bundled promo image', () {
    final result = validatePayload({'action': 'update_ui', 'asset': 'promo'});

    expect(result.assetPath, promoImage);
  });

  test('Unsupported asset is rejected without a replacement image', () {
    final result = validatePayload({'action': 'update_ui', 'asset': 'unknown'});

    expect(result.assetPath, isNull);
    expect(result.diagnostic, 'Rejected: unsupported asset.');
  });
}
