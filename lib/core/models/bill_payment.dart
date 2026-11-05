import 'payment.dart';
import 'utility_type.dart';

/// The mobile network a number belongs to. It picks the airtime/data product
/// and the MoMo channel. Numbers port, so the prefix is only a first guess.
enum MobileNetwork {
  mtn(
    label: 'MTN',
    walletLabel: 'MTN Mobile Money',
    channel: 'mtn-gh',
    productPrefix: 'Mtn',
  ),
  telecel(
    label: 'Telecel',
    walletLabel: 'Telecel Cash',
    channel: 'vodafone-gh',
    productPrefix: 'Telecel',
  ),
  airtelTigo(
    label: 'AirtelTigo',
    walletLabel: 'AirtelTigo Money',
    channel: 'tigo-gh',
    productPrefix: 'At',
  );

  const MobileNetwork({
    required this.label,
    required this.walletLabel,
    required this.channel,
    required this.productPrefix,
  });

  final String label;
  final String walletLabel;

  /// Hubtel's Receive Money channel name.
  final String channel;
  final String productPrefix;

  static const _prefixes = {
    '24': mtn,
    '25': mtn,
    '53': mtn,
    '54': mtn,
    '55': mtn,
    '59': mtn,
    '20': telecel,
    '50': telecel,
    '26': airtelTigo,
    '27': airtelTigo,
    '56': airtelTigo,
    '57': airtelTigo,
  };

  /// The network a Ghana number was issued on, from `0551234567`, `233…` or `+233…`.
  static MobileNetwork? guess(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233')) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.length == 9 ? _prefixes[digits.substring(0, 2)] : null;
  }

  static MobileNetwork? fromChannel(String? channel) {
    for (final n in values) {
      if (n.channel == channel) return n;
    }
    return null;
  }
}

enum EcgKind { prepaid, postpaid }

/// The GRID API product code for a bill. Airtime and data need the network;
/// ECG needs to know whether the meter is prepaid or postpaid.
String billProductCode(
  UtilityType type, {
  MobileNetwork? network,
  EcgKind ecgKind = EcgKind.prepaid,
}) => switch (type) {
  UtilityType.ecg => ecgKind == EcgKind.postpaid ? 'EcgPostpaid' : 'EcgPrepaid',
  UtilityType.water => 'GhanaWater',
  UtilityType.dstv => 'Dstv',
  UtilityType.gotv => 'Gotv',
  UtilityType.startimes => 'Startimes',
  UtilityType.internet => 'TelecelBroadband',
  UtilityType.airtime =>
    '${(network ?? MobileNetwork.mtn).productPrefix}Airtime',
  UtilityType.dataBundle =>
    '${(network ?? MobileNetwork.mtn).productPrefix}Data',
};

/// The utility a product code belongs to, for orders read back from the API.
UtilityType utilityTypeForProduct(String code) => switch (code) {
  'EcgPrepaid' || 'EcgPostpaid' => UtilityType.ecg,
  'GhanaWater' => UtilityType.water,
  'Dstv' => UtilityType.dstv,
  'Gotv' => UtilityType.gotv,
  'Startimes' => UtilityType.startimes,
  'TelecelBroadband' => UtilityType.internet,
  _ when code.endsWith('Airtime') => UtilityType.airtime,
  _ => UtilityType.dataBundle,
};

/// What to look up or pay: the product and how the biller identifies the account.
class BillTarget {
  const BillTarget({
    required this.productCode,
    this.accountNumber,
    this.phoneNumber,
    this.meterNumber,
  });

  final String productCode;

  /// Meter, smartcard, landline or phone being paid for.
  final String? accountNumber;

  /// The phone an ECG or water account is linked to. Defaults to the signed-in number.
  final String? phoneNumber;

  /// Which ECG meter, when the phone has several.
  final String? meterNumber;

  BillTarget withMeter(String meter) => BillTarget(
    productCode: productCode,
    accountNumber: accountNumber,
    phoneNumber: phoneNumber,
    meterNumber: meter,
  );

  Map<String, dynamic> toJson() => {
    'productCode': productCode,
    'accountNumber': ?accountNumber,
    'phoneNumber': ?phoneNumber,
    'meterNumber': ?meterNumber,
  };
}

/// A data bundle as the telco offers it right now. [value] and [amount] are
/// sent back together when ordering.
class BillBundle {
  const BillBundle({
    required this.value,
    required this.label,
    required this.amount,
  });

  final String value;
  final String label;
  final double amount;
}

/// What the biller says about an account before anything is paid.
class BillLookup {
  const BillLookup({
    required this.productCode,
    required this.accountNumber,
    required this.customerName,
    required this.nameConfirmed,
    this.amountDue,
    this.bundles = const [],
    this.minAmount,
    this.maxAmount,
    this.fixedPrice = false,
    this.chargePercent = 0,
  });

  final String productCode;
  final String accountNumber;
  final String customerName;

  /// False when the biller couldn't say whose account it is (e.g. an ECG
  /// meter not yet linked to this phone), so the customer should double-check.
  final bool nameConfirmed;
  final double? amountDue;
  final List<BillBundle> bundles;
  final double? minAmount;
  final double? maxAmount;

  /// Data bundles: the price comes from the chosen bundle, not an amount.
  final bool fixedPrice;

  /// Roughly what Hubtel adds on top when it prompts the wallet.
  final double chargePercent;
}

/// One of several ECG meters linked to a phone.
class MeterChoice {
  const MeterChoice({
    required this.meterNumber,
    required this.customerName,
    this.amountDue,
  });

  final String meterNumber;
  final String customerName;
  final double? amountDue;
}

/// What the customer sees about an order.
enum BillOrderStatus {
  awaitingPayment,
  paymentFailed,
  processing,
  completed,
  refunding,
  refunded,
}

/// A bill payment order and its MoMo payment, bill and refund.
class BillOrder {
  const BillOrder({
    required this.id,
    required this.reference,
    required this.productCode,
    required this.accountNumber,
    required this.customerName,
    required this.principal,
    required this.fee,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.channel,
    this.needsReview = false,
    this.awaitingApproval = false,
    this.maskedPhone,
    this.charges,
    this.amountCharged,
    this.paidAt,
    this.paymentError,
    this.billExternalReference,
    this.deliveredAt,
    this.refundStatus,
    this.refundAmount,
    this.savedAccountId,
    this.propertyId,
  });

  final String id;

  /// Human-facing reference, e.g. GRID-3F9A21C7B0D4.
  final String reference;
  final String productCode;
  final String accountNumber;
  final String customerName;
  final double principal;
  final double fee;
  final double total;
  final BillOrderStatus status;
  final DateTime createdAt;
  final String channel;
  final bool needsReview;

  /// The MoMo prompt is out; the customer should approve it on their phone.
  final bool awaitingApproval;
  final String? maskedPhone;

  /// Hubtel's charge and what the wallet was actually debited.
  final double? charges;
  final double? amountCharged;
  final DateTime? paidAt;
  final String? paymentError;

  /// The biller's own receipt reference, once delivered.
  final String? billExternalReference;
  final DateTime? deliveredAt;

  /// `InProgress`, `NeedsFinance` or `Completed`.
  final String? refundStatus;
  final double? refundAmount;
  final String? savedAccountId;
  final String? propertyId;

  UtilityType get type => utilityTypeForProduct(productCode);

  /// Nothing more will happen on its own.
  bool get isFinal =>
      status == BillOrderStatus.completed ||
      status == BillOrderStatus.paymentFailed ||
      status == BillOrderStatus.refunded ||
      (status == BillOrderStatus.refunding && refundStatus == 'NeedsFinance');

  String get walletLabel =>
      MobileNetwork.fromChannel(channel)?.walletLabel ?? 'Mobile Money';
}

/// How an order reads to the customer, and the [PaymentTransaction] that the
/// receipt, activity and pay hub screens already know how to show.
extension BillOrderView on BillOrder {
  TransactionStatus get transactionStatus => switch (status) {
    BillOrderStatus.completed => TransactionStatus.success,
    BillOrderStatus.paymentFailed ||
    BillOrderStatus.refunded => TransactionStatus.failed,
    _ => TransactionStatus.pending,
  };

  String get headline => switch (status) {
    BillOrderStatus.completed => 'Payment successful',
    BillOrderStatus.paymentFailed => 'Payment not completed',
    BillOrderStatus.refunding => 'Refund on the way',
    BillOrderStatus.refunded => 'Money returned',
    _ => 'Payment processing',
  };

  /// A sentence for the customer; never a provider code.
  String get message {
    final amount =
        'GH₵ ${(refundAmount ?? amountCharged ?? total).toStringAsFixed(2)}';
    if (needsReview && status != BillOrderStatus.completed) {
      return 'We\'re checking this payment with ${type.providerName}. We\'ll update it here.';
    }
    return switch (status) {
      BillOrderStatus.completed => 'Your ${type.label} payment is complete.',
      BillOrderStatus.paymentFailed =>
        paymentError == 'hubtel.unpaid'
            ? 'The approval request on your phone expired. You have not been charged.'
            : 'The payment wasn\'t approved. You have not been charged.',
      BillOrderStatus.refunding =>
        refundStatus == 'NeedsFinance'
            ? 'We couldn\'t complete the ${type.label} payment. Our team is returning $amount to you.'
            : 'We couldn\'t complete the ${type.label} payment, so we\'re returning $amount to your wallet.',
      BillOrderStatus.refunded =>
        'We couldn\'t complete the ${type.label} payment. $amount has been returned to your wallet.',
      BillOrderStatus.processing =>
        'Payment received. We\'re paying ${type.providerName} now.',
      BillOrderStatus.awaitingPayment =>
        'Waiting for you to approve the payment on your phone.',
    };
  }

  PaymentTransaction toTransaction({
    String? nickname,
    String? propertyLabel,
  }) => PaymentTransaction(
    id: id,
    reference: reference,
    type: type,
    accountNumber: accountNumber,
    accountNickname:
        nickname ?? (customerName.isNotEmpty ? customerName : type.label),
    amount: principal,
    // What came out of the wallet beyond the bill: GRID's fee and Hubtel's charge.
    fee: fee + (charges ?? 0),
    status: transactionStatus,
    createdAt: createdAt,
    paymentMethodLabel: walletLabel,
    propertyId: propertyId,
    propertyLabel: propertyLabel,
    failureReason: transactionStatus == TransactionStatus.success
        ? null
        : message,
    billerReference: billExternalReference,
  );
}
