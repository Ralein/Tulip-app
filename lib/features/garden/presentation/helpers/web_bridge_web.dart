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

void _postToIframesInNode(web.Node node) {
  if (node.isA<web.HTMLIFrameElement>()) {
    (node as web.HTMLIFrameElement).contentWindow?.postMessage('reset-camera'.toJS, '*'.toJS);
  }
  
  if (node.isA<web.Element>()) {
    final shadow = (node as web.Element).shadowRoot;
    if (shadow != null) {
      final childNodes = shadow.childNodes;
      for (int i = 0; i < childNodes.length; i++) {
        final child = childNodes.item(i);
        if (child != null) {
          _postToIframesInNode(child);
        }
      }
    }
  }

  final childNodes = node.childNodes;
  for (int i = 0; i < childNodes.length; i++) {
    final child = childNodes.item(i);
    if (child != null) {
      _postToIframesInNode(child);
    }
  }
}

void resetCameraOnWeb() {
  _postToIframesInNode(web.document.body ?? web.document.documentElement!);
}
