import 'dart:js_interop';
import 'package:web/web.dart' as web;

void initPlatformWebBridge(void Function(String slotId) onMessage) {
  web.window.addEventListener(
    'message',
    (web.MessageEvent event) {
      final data = event.data;
      if (data != null && data.isA<JSString>()) {
        final dartString = (data as JSString).toDart;
        onMessage(dartString);
      }
    }.toJS,
  );
}

void resetCameraOnWeb() {
  final iframes = web.document.querySelectorAll('iframe');
  for (int i = 0; i < iframes.length; i++) {
    final iframe = iframes.item(i) as web.HTMLIFrameElement;
    iframe.contentWindow?.postMessage('reset-camera'.toJS, '*'.toJS);
  }
}
