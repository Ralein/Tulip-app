// Conditional export to support web bridge safely across platforms
export 'web_bridge_stub.dart'
    if (dart.library.js_interop) 'web_bridge_web.dart';
