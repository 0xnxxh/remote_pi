import 'dart:io';

/// O que a plataforma consegue oferecer de navegador (plano 58, decisão B).
///
/// - [inline]: webview embutida na árvore de widgets (WKWebView no macOS,
///   WebView2 no Windows) — pane de navegador e preview de markdown/HTML.
/// - [systemBrowser]: sem webview (Linux) — "abrir navegador" delega ao
///   browser do SO via url_launcher e a UI **não** oferece o que não existe
///   (sem botão morto; preview de .md segue no renderer Flutter).
enum BrowserCapability {
  inline,
  systemBrowser;

  static BrowserCapability resolve() =>
      Platform.isMacOS || Platform.isWindows ? inline : systemBrowser;

  bool get isInline => this == inline;
}
