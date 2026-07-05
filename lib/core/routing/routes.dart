/// Route paths used across the app.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';

  static const home = '/home';
  static const pay = '/pay';
  static const services = '/services';
  static const activity = '/activity';
  static const profile = '/profile';

  static const savedAccounts = '/accounts';
  static const properties = '/properties';
  static const addProperty = '/properties/add';

  static const paymentMethods = '/profile/payment-methods';
  static const notifications = '/profile/notifications';
  static const help = '/profile/help';
  static const privacy = '/profile/privacy';

  static String payFlow(String type) => '/pay/flow/$type';
  static String property(String id) => '/properties/$id';
  static String editProperty(String id) => '/properties/$id/edit';
  static const bookService = '/services/book';
  static String serviceRequest(String id) => '/services/request/$id';
}
