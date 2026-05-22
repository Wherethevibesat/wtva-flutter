import 'package:url_launcher/url_launcher.dart';

Future<bool> openMapsSearch(String query) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openPhoneCall(String phone) async {
  final uri = Uri.parse('tel:$phone');
  return launchUrl(uri);
}
