import SwiftUI
import WebKit
import SafariServices

// MARK: - Article Detail View

struct ArticleDetailView: View {
    let article: Article

    @State private var isLoading = true
    @State private var showShareSheet = false
    @State private var dragOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.newsNavigation) private var navStore
    @AppStorage("textSizeIndex") private var textSizeIndex = 1

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER ---
            ZStack(alignment: .bottom) {
                TBTheme.highlightGradient
                    .ignoresSafeArea(edges: .top)

                HStack(alignment: .center) {
                    // Botão Voltar
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .buttonWithGlassEffect()
                    // A id força a atualização visual completa na troca de tema
                    .id("back-button-\(colorScheme)")
                    .frame(width: 44, alignment: SwiftUI.Alignment.leading)

                    Spacer()

                    Image("tb-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 26)

                    Spacer()

                    // Botão Compartilhar
                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .buttonWithGlassEffect()
                    // A id evita que o ícone "bugue" ou suma na troca de tema
                    .id("share-button-\(colorScheme)")
                    .frame(width: 44, alignment: SwiftUI.Alignment.trailing)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .frame(height: 100)

            // --- CONTEÚDO ---
            ZStack {
                ArticleWebView(
                    article: article,
                    isLoading: $isLoading,
                    colorScheme: colorScheme,
                    textSizeIndex: textSizeIndex,
                    onTecnoblogLink: { url in
                        navStore.path.append(url)
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                .opacity(isLoading ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: isLoading)

                if isLoading {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Carregando...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .offset(x: dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard value.translation.width > 0,
                          abs(value.translation.width) > abs(value.translation.height) * 1.5
                    else { return }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) { dragOffset = 0 }
                    }
                }
        )
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: article.link) {
                ShareSheet(items: [url])
            }
        }
    }
}

// MARK: - WebView Implementation

struct ArticleWebView: UIViewRepresentable {
    let article: Article
    @Binding var isLoading: Bool
    let colorScheme: ColorScheme
    let textSizeIndex: Int
    var onTecnoblogLink: (URL) -> Void

    private var uiStyle: UIUserInterfaceStyle { colorScheme == .dark ? .dark : .light }
    private var bg: String           { UIColor.systemBackground.toHex(for: uiStyle) }
    private var textColor: String    { UIColor.label.toHex(for: uiStyle) }
    private var textSecColor: String { UIColor.secondaryLabel.toHex(for: uiStyle) }
    private var borderColor: String  { UIColor.separator.toHex(for: uiStyle) }
    private var linkColor: String    { colorScheme == .dark ? "#409CFF" : "#0073E6" }
    private let accentColor          = "#0073E6"

    private var fontSizePx: String {
        switch textSizeIndex {
        case 0: return "15"
        case 2: return "21"
        default: return "17"
        }
    }

    func makeUIView(context: Context) -> WKWebView {
        let zoomScript = "var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; document.getElementsByTagName('head')[0].appendChild(meta);"
        let userScript = WKUserScript(source: zoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.alpha = 0

        context.coordinator.targetURLString = article.link

        if let url = URL(string: article.link) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let themeScript = buildThemeOnlyScript()
        if !isLoading && themeScript != context.coordinator.lastThemeScript {
            context.coordinator.lastThemeScript = themeScript
            webView.evaluateJavaScript(themeScript, completionHandler: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func buildScript() -> String {
        let fallbackDate = article.pubDate.formatted(date: .long, time: .omitted)
        let fallbackTitle = article.title.replacingOccurrences(of: "'", with: "\\'")
        let fallbackAuthor = article.author.replacingOccurrences(of: "'", with: "\\'")
        let fallbackCategory = article.categories.first?.uppercased() ?? ""

        return """
        (function() {
            var extractedTitle = '\(fallbackTitle)';
            var extractedCategory = '\(fallbackCategory)';
            var extractedAuthor = '\(fallbackAuthor)';
            var extractedDate = '\(fallbackDate)';
            var tEl = document.querySelector('h1');
            if (tEl) extractedTitle = tEl.innerText.trim();

            ['header', 'footer', 'aside', '.sidebar', '.comments-area', '.tb-related'].forEach(function(sel) {
                document.querySelectorAll(sel).forEach(function(el) { el.remove(); });
            });

            var content = document.querySelector('.entry-content') || document.querySelector('.post-content') || document.querySelector('.article-content');
            if (content) {
                var clone = content.cloneNode(true);
                document.body.innerHTML = '';
                document.body.appendChild(clone);
            }

            var hdr = document.createElement('div');
            hdr.id = 'tb-native-header';
            hdr.innerHTML = '<div style="padding: 0 16px;"><span style="background:\(accentColor);display:inline-block;color:#fff;font-size:11px;font-weight:700;padding:3px 10px;border-radius:20px;margin-bottom:10px;">' + extractedCategory + '</span><h1 style="font-size:22px;font-weight:700;line-height:1.3;margin:0 0 8px 0;">' + extractedTitle + '</h1><div style="font-size:13px;color:\(textSecColor);">Por ' + extractedAuthor + ' • ' + extractedDate + '</div><div style="height:1px;background:\(borderColor);margin:12px 0 20px 0;"></div></div>';
            document.body.insertBefore(hdr, document.body.firstChild);
            \(buildThemeOnlyScript())
        })();
        """
    }

    func buildThemeOnlyScript() -> String {
        """
        (function applyTBTheme() {
            var old = document.getElementById('tb-theme');
            if (old) old.parentNode.removeChild(old);
            var css = 'html, body { background: \(bg) !important; } body { margin: 0 !important; padding: 0 !important; color: \(textColor) !important; font-family: -apple-system, sans-serif !important; font-size: \(fontSizePx)px !important; line-height: 1.75 !important; }';
            css += 'a { color: \(linkColor) !important; text-decoration: none !important; } .entry-content, article { padding: 0 16px 80px 16px !important; }';
            css += 'img { max-width: 100% !important; height: auto !important; border-radius: 8px !important; margin: 12px 0 !important; }';
            var s = document.createElement('style');
            s.id = 'tb-theme';
            s.innerHTML = css;
            document.head.appendChild(s);
        })();
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ArticleWebView
        var targetURLString: String = ""
        var lastThemeScript: String = ""
        init(parent: ArticleWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow); return
            }
            decisionHandler(.cancel)
            DispatchQueue.main.async {
                if url.host?.contains("tecnoblog.net") == true {
                    self.parent.onTecnoblogLink(url)
                } else {
                    let safari = SFSafariViewController(url: url)
                    UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first { $0.isKeyWindow } }.first?.rootViewController?.present(safari, animated: true)
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(parent.buildScript()) { [weak self] _, _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIView.animate(withDuration: 0.2) { webView.alpha = 1 }
                    self.parent.isLoading = false
                    self.lastThemeScript = self.parent.buildThemeOnlyScript()
                }
            }
        }
    }
}

// MARK: - MacMagazine UI Extensions

extension View {
    func buttonWithGlassEffect() -> some View {
        modifier(ButtonWithGlassEffect())
    }
}

private struct ButtonWithGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            // Forçamos o foregroundStyle para garantir que o ícone mude de cor
            .foregroundStyle(.primary)
            .background {
                if #available(iOS 26.0, *) {
                    // Placeholder para versão futura do MacMagazine
                    Circle().glassEffect(.regular.interactive(), in: .circle)
                } else {
                    // Fallback visual idêntico ao efeito "Liquid Glass"
                    Circle().fill(.ultraThinMaterial)
                }
            }
    }
}

// MARK: - General Helpers

private extension UIColor {
    func toHex(for style: UIUserInterfaceStyle) -> String {
        let resolved = resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
