import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Canonical hosted legal documents. Single source of truth — used by both the
/// welcome screen and Settings so the URLs never drift apart.
const termsUrl = 'https://getfafo.app/terms';
const privacyUrl = 'https://getfafo.app/privacy';

/// Opens [url] in the device's external browser. Shows a SnackBar on failure so
/// the tap never fails silently.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
