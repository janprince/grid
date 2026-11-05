import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid/core/data/api/api_client.dart';
import 'package:grid/core/data/api/live_repositories.dart';
import 'package:grid/core/data/api/session_store.dart';
import 'package:grid/core/data/repositories.dart';
import 'package:grid/core/models/models.dart';

/// Answers requests from a handler instead of the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final (int, Object?) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _money(String amount) => {
  'amount': amount,
  'currency': 'GHS',
};

/// An order as GET /orders/{id} returns it.
Map<String, dynamic> _order({
  String status = 'AwaitingPayment',
  Map<String, dynamic>? refund,
}) => {
  'id': 'o1',
  'reference': 'GRID-ABC123',
  'productCode': 'EcgPrepaid',
  'accountNumber': 'P191177631',
  'customerName': 'TEST CUSTOMER',
  'nameConfirmed': true,
  'principal': _money('100.00'),
  'fee': _money('0.00'),
  'total': _money('100.00'),
  'status': status,
  'needsReview': false,
  'nextAction': status == 'AwaitingPayment'
      ? {
          'kind': 'ApproveOnPhone',
          'channel': 'mtn-gh',
          'maskedPhone': '23355****567',
        }
      : null,
  'payment': {
    'state': 'Pending',
    'channel': 'mtn-gh',
    'maskedPhone': '23355****567',
    'charges': _money('1.00'),
    'amountCharged': _money('101.00'),
    'paidAt': null,
    'error': null,
  },
  'bill': status == 'Completed'
      ? {
          'state': 'Succeeded',
          'resultKind': 'RemoteMeterCredit',
          'externalReference': 'ECG-77',
          'deliveredAt': '2026-11-03T10:00:00Z',
        }
      : null,
  'refund': refund,
  'savedAccountId': 'a1',
  'propertyId': null,
  'createdAt': '2026-11-03T09:59:00Z',
};

void main() {
  late SessionStore sessions;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    sessions = SessionStore();
  });

  LiveBillPaymentsApi api(_FakeAdapter adapter) => LiveBillPaymentsApi(
    ApiClient(sessions, dio: Dio()..httpClientAdapter = adapter),
  );

  test('placing an order sends the idempotency key and GHS money', () async {
    final adapter = _FakeAdapter(
      (_) => (201, {'success': true, 'data': _order()}),
    );
    final order = await api(adapter).placeOrder(
      target: const BillTarget(
        productCode: 'EcgPrepaid',
        accountNumber: 'P191177631',
      ),
      amount: 100,
      idempotencyKey: 'key-1',
      channel: 'mtn-gh',
      savedAccountId: 'a1',
    );

    final request = adapter.requests.single;
    expect(request.path, '/orders');
    expect(request.headers['Idempotency-Key'], 'key-1');
    expect(request.data, {
      'productCode': 'EcgPrepaid',
      'accountNumber': 'P191177631',
      'amount': {'amount': '100.00', 'currency': 'GHS'},
      'channel': 'mtn-gh',
      'savedAccountId': 'a1',
    });
    expect(order.status, BillOrderStatus.awaitingPayment);
    expect(order.awaitingApproval, isTrue);
    expect(order.amountCharged, 101);
    expect(order.walletLabel, 'MTN Mobile Money');
  });

  test(
    'a delivered order reads as a successful transaction with the biller reference',
    () async {
      final adapter = _FakeAdapter(
        (_) => (200, {'success': true, 'data': _order(status: 'Completed')}),
      );
      final order = await api(adapter).order('o1');
      final tx = order.toTransaction(nickname: 'Home meter');
      expect(order.isFinal, isTrue);
      expect(tx.status, TransactionStatus.success);
      expect(tx.billerReference, 'ECG-77');
      expect(tx.fee, 1); // Hubtel's charge on top.
      expect(tx.accountNickname, 'Home meter');
    },
  );

  test(
    'a refund in progress is pending, with a sentence for the customer',
    () async {
      final adapter = _FakeAdapter(
        (_) => (
          200,
          {
            'success': true,
            'data': _order(
              status: 'Refunding',
              refund: {
                'status': 'InProgress',
                'amount': _money('100.00'),
                'reason': 'BillFailed',
              },
            ),
          },
        ),
      );
      final order = await api(adapter).order('o1');
      expect(order.isFinal, isFalse);
      expect(order.toTransaction().status, TransactionStatus.pending);
      expect(order.message, contains('returning GH₵ 100.00'));
    },
  );

  test('several meters on one phone become a choice', () async {
    final adapter = _FakeAdapter(
      (_) => (
        409,
        {
          'success': false,
          'error': {
            'code': 'bills.meter_selection_required',
            'message': 'Choose the meter to pay for.',
            'detail': [
              {
                'meterNumber': 'G131099826',
                'customerName': 'THOMAS ANANE',
                'amountDue': _money('-1.14'),
              },
              {
                'meterNumber': '24911947992',
                'customerName': 'ADEMAU LYDIA',
                'amountDue': null,
              },
            ],
            'fields': [],
          },
        },
      ),
    );
    await expectLater(
      api(adapter).lookup(const BillTarget(productCode: 'EcgPrepaid')),
      throwsA(
        isA<MeterSelectionRequired>().having(
          (e) => e.meters.map((m) => m.meterNumber),
          'meters',
          ['G131099826', '24911947992'],
        ),
      ),
    );
  });

  test(
    'data lookups return the telco bundles and a fixed price rule',
    () async {
      final adapter = _FakeAdapter(
        (_) => (
          200,
          {
            'success': true,
            'data': {
              'productCode': 'MtnData',
              'accountNumber': '233244000111',
              'customerName': '',
              'nameConfirmed': false,
              'beneficiaryPhone': '233244000111',
              'amountDue': null,
              'bundles': [
                {
                  'value': 'flexi_data_bundle',
                  'label': '2.38GB',
                  'amount': _money('40.00'),
                },
              ],
              'amountRule': {'min': null, 'max': null, 'fixed': true},
              'chargePercent': 1,
            },
          },
        ),
      );
      final lookup = await api(adapter).lookup(
        const BillTarget(productCode: 'MtnData', accountNumber: '0244000111'),
      );
      expect(lookup.fixedPrice, isTrue);
      expect(lookup.bundles.single.amount, 40);
      expect(lookup.chargePercent, 1);
    },
  );

  test('product codes follow the network and ECG kind', () {
    expect(
      billProductCode(UtilityType.airtime, network: MobileNetwork.telecel),
      'TelecelAirtime',
    );
    expect(
      billProductCode(
        UtilityType.dataBundle,
        network: MobileNetwork.airtelTigo,
      ),
      'AtData',
    );
    expect(
      billProductCode(UtilityType.ecg, ecgKind: EcgKind.postpaid),
      'EcgPostpaid',
    );
    expect(MobileNetwork.guess('+233 20 123 4567'), MobileNetwork.telecel);
    expect(utilityTypeForProduct('MtnAirtime'), UtilityType.airtime);
  });
}
