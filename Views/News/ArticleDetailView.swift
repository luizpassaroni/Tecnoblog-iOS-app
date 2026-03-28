//
//  ArticleDetailView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//


import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let article: Article

    @State private var isLoading = true
    @State private var showShareSheet = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("textSizeIndex") private var textSizeIndex = 1

    var body: some View {
        ZStack {
            ArticleWebView(
                article: article,
                isLoading: $isLoading,
                colorScheme: colorScheme,
                textSizeIndex: textSizeIndex
            )
            .ignoresSafeArea(edges: .bottom)

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
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: article.link) {
                ShareSheet(items: [url])
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { showShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - UIColor → Hex

private extension UIColor {
    func toHex(for style: UIUserInterfaceStyle) -> String {
        let resolved = resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - WebView

struct ArticleWebView: UIViewRepresentable {
    let article: Article
    @Binding var isLoading: Bool
    let colorScheme: ColorScheme
    let textSizeIndex: Int

    private var uiStyle: UIUserInterfaceStyle { colorScheme == .dark ? .dark : .light }
    private var bg: String           { UIColor.systemBackground.toHex(for: uiStyle) }
    private var bgSecondary: String  { UIColor.secondarySystemBackground.toHex(for: uiStyle) }
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

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = false
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0

        webView.load(URLRequest(url: URL(string: article.link)!))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        context.coordinator.buildScript = buildScript
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, buildScript: buildScript)
    }

    // MARK: - Script principal

    private func buildScript() -> String {
        let fallbackDate = article.pubDate.formatted(date: .long, time: .omitted)

        let fallbackTitle = article.title
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\n", with: " ")

        let fallbackAuthor = article.author
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")

        let fallbackCategory = article.categories.first.map { $0.uppercased() } ?? ""

        return """
        (function() {

            // ── 0. EXTRAI DADOS DO DOM ────────────────────────────
            // OBRIGATORIAMENTE o primeiro passo: logo abaixo o
            // innerHTML = '' destrói o DOM original — qualquer
            // querySelector depois disso não encontra mais nada.

            var extractedTitle = '\(fallbackTitle)';
            var extractedCategory = '\(fallbackCategory)';
            var extractedAuthor = '\(fallbackAuthor)';
            var extractedDate = '\(fallbackDate)';

            var titleCandidates = [
                document.querySelector('h1.entry-title'),
                document.querySelector('h1.post-title'),
                document.querySelector('.entry-header h1'),
                document.querySelector('.post-header h1'),
                document.querySelector('article h1'),
                document.querySelector('h1')
            ];
            for (var t = 0; t < titleCandidates.length; t++) {
                if (titleCandidates[t] && titleCandidates[t].innerText.trim() !== '') {
                    extractedTitle = titleCandidates[t].innerText.trim();
                    break;
                }
            }

            var catEl = document.querySelector('.entry-header .cat-links a, .post-category a, .entry-category a, .cat-links a, .category a');
            if (catEl && catEl.innerText.trim() !== '') {
                extractedCategory = catEl.innerText.trim().toUpperCase();
            }

            var authorEl = document.querySelector('.author.vcard a, [rel="author"], .entry-meta .author, .post-author a');
            if (authorEl && authorEl.innerText.trim() !== '') {
                extractedAuthor = authorEl.innerText.trim();
            }

            var dateEl = document.querySelector('time.entry-date, time[datetime], .entry-meta time, .post-date time');
            if (dateEl && dateEl.getAttribute('datetime')) {
                var d = new Date(dateEl.getAttribute('datetime'));
                if (!isNaN(d)) {
                    extractedDate = d.toLocaleDateString('pt-BR', {
                        year: 'numeric', month: 'long', day: 'numeric'
                    });
                }
            }

            // ── 1. REMOVE HEADER / ELEMENTOS DE TOPO ─────────────
            [
                'header',
                '.container-header-bar',
                '#breadcrumbs',
                '#tb-banner-google'
            ].forEach(function(sel) {
                try {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.parentNode && el.parentNode.removeChild(el);
                    });
                } catch(e) {}
            });

            // ── 2. REMOVE FOOTER / SIDEBAR / EXTRAS ──────────────
            [
                'footer', '.footer', '#footer',
                'aside', '.sidebar', '#sidebar',
                '.widget-area', '.site-footer',
                '.nav-links', '.navigation',
                '#comments', '.comments-area',
                '.tb-related', '[class*="related-posts"]',
                '[class*="newsletter"]',
                '.tb-player', '#tb-player',
                '.tecnocast', '.achados', '.tb-achados',
                '.infinite-scroll-footer'
            ].forEach(function(sel) {
                try {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.parentNode && el.parentNode.removeChild(el);
                    });
                } catch(e) {}
            });

            // ── 3. ISOLA O CONTEÚDO PRINCIPAL ────────────────────
            var contentSelectors = [
                '.entry-content',
                '.post-content',
                '.article-content',
                '.article-body',
                '.post-body',
                '[itemprop="articleBody"]'
            ];

            var content = null;
            for (var i = 0; i < contentSelectors.length; i++) {
                content = document.querySelector(contentSelectors[i]);
                if (content) break;
            }

            if (content) {
                var clone = content.cloneNode(true);
                document.body.innerHTML = '';
                document.body.appendChild(clone);
            } else {
                var art = document.querySelector('article');
                if (art) {
                    var clone = art.cloneNode(true);
                    document.body.innerHTML = '';
                    document.body.appendChild(clone);
                }
            }

            // ── 4. REMOVE SOBRAS DENTRO DO CONTEÚDO ──────────────
            [
                '.adsbygoogle', '.ad', '.ads',
                '[class*="advertisement"]',
                '.sharedaddy', '.sd-sharing',
                '.jp-relatedposts',
                '.yarpp-related', '.related-posts',
                '[class*="related"]',
                '[class*="newsletter"]',
                '[class*="signup"]',
                '.post-tags', '.tags-links',
                '.post-author-box', '.author-bio',
                '[class*="comment"]',
                '#disqus_thread', '[id*="disqus"]',
                '.wp-block-group:empty',
                'nav.tags',
                '[class*="cookie"]',
                '[id*="cookie"]',
                '.lgpd', '[class*="lgpd"]', '[id*="lgpd"]'
            ].forEach(function(sel) {
                try {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.parentNode && el.parentNode.removeChild(el);
                    });
                } catch(e) {}
            });

            // ── 5. ESCONDE TÍTULO/META DUPLICADOS ────────────────
            [
                'h1.entry-title', 'h1.post-title',
                '.entry-header h1', '.post-header h1',
                '.entry-header .cat-links',
                '.post-category', '.entry-category',
                '.entry-header', '.post-header',
                '.entry-meta', '.post-meta'
            ].forEach(function(sel) {
                try {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.style.setProperty('display', 'none', 'important');
                    });
                } catch(e) {}
            });

            // ── 6. CORRIGE IMAGENS ────────────────────────────────
            document.querySelectorAll('img').forEach(function(img) {
                img.removeAttribute('width');
                img.removeAttribute('height');
                img.removeAttribute('srcset');
                img.removeAttribute('sizes');
                img.style.setProperty('max-width', '100%', 'important');
                img.style.setProperty('width', '100%', 'important');
                img.style.setProperty('height', 'auto', 'important');
                img.style.setProperty('display', 'block', 'important');
                img.style.setProperty('border-radius', '8px', 'important');
                img.style.setProperty('margin', '12px 0', 'important');
            });

            document.querySelectorAll('iframe').forEach(function(iframe) {
                iframe.removeAttribute('width');
                iframe.removeAttribute('height');
                iframe.style.setProperty('max-width', '100%', 'important');
                iframe.style.setProperty('width', '100%', 'important');
                iframe.style.setProperty('aspect-ratio', '16/9', 'important');
                iframe.style.setProperty('height', 'auto', 'important');
                iframe.style.setProperty('border-radius', '8px', 'important');
                iframe.style.setProperty('margin', '12px 0', 'important');
            });

            document.querySelectorAll('figure, .wp-block-image').forEach(function(fig) {
                fig.style.setProperty('max-width', '100%', 'important');
                fig.style.setProperty('width', '100%', 'important');
                fig.style.setProperty('margin', '16px 0', 'important');
                fig.style.setProperty('padding', '0', 'important');
                fig.style.setProperty('box-sizing', 'border-box', 'important');
            });

            // ── 7. INJETA HEADER NATIVO ───────────────────────────
            var oldHdr = document.getElementById('tb-native-header');
            if (oldHdr) oldHdr.parentNode.removeChild(oldHdr);

            var hdr = document.createElement('div');
            hdr.id = 'tb-native-header';
            var html = '';
            if (extractedCategory !== '') {
                html += '<span id="tb-cat">' + extractedCategory + '</span>';
            }
            html += '<h1 id="tb-title">' + extractedTitle + '</h1>';
            html += '<div id="tb-meta">';
            if (extractedAuthor !== '') {
                html += '<span>' + extractedAuthor + '</span><span class="tb-dot"> · </span>';
            }
            html += '<span>' + extractedDate + '</span>';
            html += '</div>';
            html += '<div id="tb-divider"></div>';
            hdr.innerHTML = html;
            document.body.insertBefore(hdr, document.body.firstChild);

            // ── 8. APLICA TEMA ────────────────────────────────────
            applyTBTheme(
                '\(bg)', '\(bgSecondary)',
                '\(textColor)', '\(textSecColor)',
                '\(borderColor)', '\(linkColor)', '\(accentColor)',
                '\(fontSizePx)'
            );

        })();

        function applyTBTheme(bg, bgSec, text, textSec, border, link, accent, fontSize) {
            var old = document.getElementById('tb-theme');
            if (old) old.parentNode.removeChild(old);

            var existingMeta = document.querySelector('meta[name="viewport"]');
            if (existingMeta) {
                existingMeta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
            } else {
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
            }

            var css = '';

            css += 'html { background: ' + bg + ' !important; }';
            css += 'body { margin: 0 !important; padding: 0 !important; background: ' + bg + ' !important; color: ' + text + ' !important; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif !important; font-size: ' + fontSize + 'px !important; line-height: 1.75 !important; -webkit-text-size-adjust: none !important; }';
            css += '* { background-color: transparent !important; box-sizing: border-box !important; }';
            css += 'html, body { background-color: ' + bg + ' !important; }';
            css += '.entry-content, .post-content, .article-content, .article-body, .post-body, [itemprop="articleBody"], article { background-color: ' + bg + ' !important; color: ' + text + ' !important; max-width: 100% !important; padding: 0 16px 80px 16px !important; margin: 0 !important; overflow: hidden !important; }';
            css += '#tb-native-header { background-color: ' + bg + ' !important; padding: 0px 16px 0 16px !important; }';
            css += '#tb-cat { background-color: ' + accent + ' !important; display: inline-block !important; color: #fff !important; font-size: 11px !important; font-weight: 700 !important; padding: 3px 10px !important; border-radius: 20px !important; letter-spacing: 0.5px !important; margin-bottom: 10px !important; }';
            css += 'blockquote { background-color: ' + bgSec + ' !important; }';
            css += 'code, pre { background-color: ' + bgSec + ' !important; }';
            css += 'th { background-color: ' + accent + ' !important; }';
            css += 'tr:nth-child(even) td { background-color: ' + bgSec + ' !important; }';

            css += '#tb-title { font-size: 22px !important; font-weight: 700 !important; line-height: 1.3 !important; color: ' + text + ' !important; margin: 0 0 8px 0 !important; padding: 0 !important; }';
            css += '#tb-meta { font-size: 13px !important; color: ' + textSec + ' !important; margin-bottom: 4px !important; }';
            css += '.tb-dot { color: ' + textSec + ' !important; }';
            css += '#tb-divider { height: 1px !important; background-color: ' + border + ' !important; margin: 12px 0 20px 0 !important; }';

            css += 'p { color: ' + text + ' !important; margin-bottom: 1.2em !important; }';
            css += 'h2, h3, h4, h5, h6 { color: ' + text + ' !important; line-height: 1.3 !important; margin-top: 1.4em !important; margin-bottom: 0.6em !important; }';
            css += 'h2 { font-size: 1.3em !important; } h3 { font-size: 1.15em !important; }';
            css += 'strong, b, em, i, li, td, span { color: ' + text + ' !important; }';
            css += 'a, a:visited { color: ' + link + ' !important; text-decoration: none !important; }';

            css += 'img { max-width: 100% !important; width: 100% !important; height: auto !important; border-radius: 8px !important; display: block !important; margin: 12px 0 !important; object-fit: contain !important; }';
            css += 'figure, .wp-block-image { max-width: 100% !important; width: 100% !important; margin: 16px 0 !important; padding: 0 !important; overflow: hidden !important; }';
            css += 'figcaption { font-size: 13px !important; color: ' + textSec + ' !important; text-align: center !important; margin-top: 4px !important; }';

            css += 'iframe { max-width: 100% !important; width: 100% !important; aspect-ratio: 16/9 !important; height: auto !important; border-radius: 8px !important; margin: 12px 0 !important; }';

            css += 'blockquote { border-left: 4px solid ' + accent + ' !important; margin: 16px 0 !important; padding: 12px 16px !important; border-radius: 0 8px 8px 0 !important; color: ' + textSec + ' !important; font-style: italic !important; }';

            css += 'code, pre { border-radius: 6px !important; font-family: SF Mono, Menlo, monospace !important; font-size: 0.88em !important; color: ' + text + ' !important; }';
            css += 'code { padding: 2px 6px !important; } pre { padding: 12px !important; overflow-x: auto !important; margin: 12px 0 !important; }';

            css += 'ul, ol { color: ' + text + ' !important; padding-left: 1.5em !important; margin-bottom: 1em !important; }';
            css += 'li { margin-bottom: 0.4em !important; }';

            css += 'table { width: 100% !important; border-collapse: collapse !important; margin: 16px 0 !important; font-size: 0.9em !important; }';
            css += 'th { color: #fff !important; padding: 8px 12px !important; text-align: left !important; }';
            css += 'td { padding: 8px 12px !important; border-bottom: 1px solid ' + border + ' !important; color: ' + text + ' !important; }';

            css += 'hr { border: none !important; border-top: 1px solid ' + border + ' !important; margin: 24px 0 !important; }';

            var s = document.createElement('style');
            s.id = 'tb-theme';
            s.innerHTML = css;
            document.head.appendChild(s);
        }
        """
    }

    private func recolorScript() -> String {
        "applyTBTheme('\(bg)','\(bgSecondary)','\(textColor)','\(textSecColor)','\(borderColor)','\(linkColor)','\(accentColor)','\(fontSizePx)');"
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var buildScript: () -> String

        init(isLoading: Binding<Bool>, buildScript: @escaping () -> String) {
            _isLoading = isLoading
            self.buildScript = buildScript
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Roda o script completo a cada página carregada.
            // A extração do título/categoria/data acontece no passo 0,
            // antes de qualquer manipulação do DOM.
            webView.evaluateJavaScript(buildScript()) { _, _ in }
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               !url.absoluteString.contains("tecnoblog.net") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
