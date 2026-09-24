import 'package:flutter/services.dart';

const _channel = MethodChannel('bondoolai/share');

/// Opens the Android share sheet. Returns false if sharing isn't available,
/// in which case the text has been copied to the clipboard instead.
Future<bool> shareText(String text) async {
  try {
    await _channel.invokeMethod<void>('shareText', {'text': text});
    return true;
  } on MissingPluginException {
    await Clipboard.setData(ClipboardData(text: text));
    return false;
  } on PlatformException {
    await Clipboard.setData(ClipboardData(text: text));
    return false;
  }
}
