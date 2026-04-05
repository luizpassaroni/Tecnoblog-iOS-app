//
//  ArticleDetailView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

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

                HStack {
                    Spacer()
                    Image("tb-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28)
                        .offset(y: -12)
                    Spacer()
                }

                HStack(alignment: .center) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .tbGlassButton()
                    .frame(width: 44, alignment: .leading)

                    Spacer()

                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .tbGlassButton()
                    .frame(width: 44, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
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
        let config = WKWebViewConfiguration()

        let viewportScript = WKUserScript(
            source: """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(meta);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(viewportScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bouncesZoom = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.alpha = 0

        if let url = URL(string: article.link) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self

        // ✅ Quando o tema muda, reaplicamos CSS + cores do cabeçalho juntos
        let themeScript = buildThemeOnlyScript()
        if !isLoading && themeScript != context.coordinator.lastThemeScript {
            context.coordinator.lastThemeScript = themeScript
            webView.evaluateJavaScript(themeScript, completionHandler: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    // MARK: - Scripts

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

            // ─── 1. Remove elementos estruturais ────────────────────────────────
            ['header', 'footer', 'aside', 'nav',
             '.sidebar', '.comments-area', '.tb-related',
             'nav.tags', '.tags', '.cookie-bar', '.newsletter-bar'].forEach(function(sel) {
                document.querySelectorAll(sel).forEach(function(el) { el.remove(); });
            });

            // ─── 2. Isola conteúdo principal ────────────────────────────────────
            var content = document.querySelector('.entry-content')
                       || document.querySelector('.post-content')
                       || document.querySelector('.article-content');
            if (content) {
                var clone = content.cloneNode(true);
                document.body.innerHTML = '';
                document.body.appendChild(clone);
            }

            // ─── 3. Remove containers de anúncio ────────────────────────────────
            var adSelectors = [
                'div[id^="div-gpt-ad-"]',
                'ins.adsbygoogle',
                '.tb-ad', '.tb-ads', '.ad-wrapper', '.ad-container',
                '.wp-block-ad', '.widget_custom_html',
                '[class*="adsbygoogle"]',
                '[class*="-ad-"]',
                '[id*="-ad-"]',
                '[id^="google_ads"]',
                'iframe[src*="doubleclick"]',
                'iframe[src*="googlesyndication"]',
                'iframe[src*="adservice"]'
            ];
            adSelectors.forEach(function(sel) {
                document.querySelectorAll(sel).forEach(function(el) { el.remove(); });
            });

            // ─── 4. Colapsa blocos vazios ────────────────────────────────────────
            document.querySelectorAll('div, section, p').forEach(function(el) {
                var hasText  = el.innerText && el.innerText.trim().length > 0;
                var hasImage = el.querySelector('img') !== null;
                var rect = el.getBoundingClientRect();
                if (!hasText && !hasImage && rect.height > 40) {
                    el.style.display = 'none';
                }
            });

            // ─── 5. Injeta cabeçalho nativo ─────────────────────────────────────
            // As cores do autor/data/divider são definidas via CSS variables
            // para poderem ser atualizadas dinamicamente sem recriar o DOM.
            var hdr = document.createElement('div');
            hdr.id = 'tb-native-header';
            hdr.innerHTML =
                '<div style="padding: 0 16px;">' +
                    '<span style="background:\(accentColor);display:inline-block;color:#fff;font-size:11px;font-weight:700;padding:3px 10px;border-radius:20px;margin-bottom:10px;">'
                        + extractedCategory +
                    '</span>' +
                    '<h1 style="font-size:22px;font-weight:700;line-height:1.3;margin:0 0 8px 0;">'
                        + extractedTitle +
                    '</h1>' +
                    // ✅ Usa classe tb-meta para que o buildThemeOnlyScript()
                    // possa atualizar a cor via CSS sem recriar o elemento
                    '<div class="tb-meta" style="font-size:13px;">Por ' + extractedAuthor + ' \u{2022} ' + extractedDate + '</div>' +
                    '<div class="tb-divider" style="height:1px;margin:12px 0 20px 0;"></div>' +
                '</div>';
            document.body.insertBefore(hdr, document.body.firstChild);

            // ─── 6. Imagens clicáveis ────────────────────────────────────────────
            document.querySelectorAll('img').forEach(function(img) {
                img.style.cursor = 'pointer';
                img.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    window.location.href = 'tbimage://' + encodeURIComponent(img.src);
                });
            });

            \(buildThemeOnlyScript())
        })();
        """
    }

    // ✅ CORREÇÃO PRINCIPAL: além do CSS global, atualiza explicitamente
    // as cores de .tb-meta e .tb-divider que estavam hardcoded no HTML
    // e por isso não reagiam à mudança de tema.
    func buildThemeOnlyScript() -> String {
        """
        (function applyTBTheme() {
            // CSS global
            var old = document.getElementById('tb-theme');
            if (old) old.parentNode.removeChild(old);
            var css = 'html, body { background: \(bg) !important; }';
            css += 'body { margin: 0 !important; padding: 0 !important; color: \(textColor) !important; font-family: -apple-system, sans-serif !important; font-size: \(fontSizePx)px !important; line-height: 1.75 !important; }';
            css += 'a { color: \(linkColor) !important; text-decoration: none !important; }';
            css += '.entry-content, article { padding: 0 16px 80px 16px !important; }';
            css += 'img { max-width: 100% !important; height: auto !important; border-radius: 8px !important; margin: 12px 0 !important; cursor: pointer; }';
            var s = document.createElement('style');
            s.id = 'tb-theme';
            s.innerHTML = css;
            document.head.appendChild(s);

            // ✅ Atualiza inline as cores do cabeçalho nativo que não são
            // cobertas pelo CSS global (autor, data e divisor).
            document.querySelectorAll('.tb-meta').forEach(function(el) {
                el.style.color = '\(textSecColor)';
            });
            document.querySelectorAll('.tb-divider').forEach(function(el) {
                el.style.background = '\(borderColor)';
            });
        })();
        """
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ArticleWebView
        var lastThemeScript: String = ""

        init(parent: ArticleWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow); return
            }

            if url.scheme == "tbimage" {
                decisionHandler(.cancel)
                let encoded = url.absoluteString.replacingOccurrences(of: "tbimage://", with: "")
                if let decoded = encoded.removingPercentEncoding,
                   let imageURL = URL(string: decoded) {
                    DispatchQueue.main.async { self.presentImageViewer(imageURL) }
                }
                return
            }

            guard navigationAction.navigationType == .linkActivated else {
                decisionHandler(.allow); return
            }

            decisionHandler(.cancel)
            DispatchQueue.main.async {
                if url.host?.contains("tecnoblog.net") == true {
                    self.parent.onTecnoblogLink(url)
                } else {
                    let safari = SFSafariViewController(url: url)
                    self.topViewController()?.present(safari, animated: true)
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

        private func presentImageViewer(_ url: URL) {
            let imageVC = ImageViewerController(imageURL: url)
            let nav = UINavigationController(rootViewController: imageVC)
            nav.modalPresentationStyle = .fullScreen
            topViewController()?.present(nav, animated: true)
        }

        private func topViewController() -> UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController?
                .topmostViewController()
        }
    }
}

// MARK: - Image Viewer Controller

final class ImageViewerController: UIViewController {
    private let imageURL: URL
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var activityIndicator = UIActivityIndicatorView(style: .large)

    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain, target: self, action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain, target: self, action: #selector(shareTapped)
        )
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)

        activityIndicator.color = .white
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin,
                                              .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        loadImage()
    }

    private func loadImage() {
        URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                if let data = data, let image = UIImage(data: data) {
                    self.imageView.image = image
                }
            }
        }.resume()
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func shareTapped() {
        guard let image = imageView.image else { return }
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activity, animated: true)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let rect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
            scrollView.zoom(to: rect, animated: true)
        }
    }
}

extension ImageViewerController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}

// MARK: - Extensions

extension View {
    func tbGlassButton() -> some View {
        self.buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .foregroundStyle(.primary)
            .modifier(GlassButtonModifier())
    }
}

private struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(.clear, in: Circle())
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

private extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topmostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topmostViewController() ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topmostViewController() ?? self
        }
        return self
    }
}

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
