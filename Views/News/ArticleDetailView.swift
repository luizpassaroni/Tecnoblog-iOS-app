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
    @State private var dragOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("textSizeIndex") private var textSizeIndex = 1

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER CUSTOMIZADO ---
            ZStack(alignment: .bottom) {
                TBTheme.highlightGradient
                    .ignoresSafeArea(edges: .top)

                HStack(alignment: .center) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                    .buttonWithGlassEffect()
                    .frame(width: 44, alignment: .leading)

                    Spacer()

                    Image("tb-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 26)

                    Spacer()

                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                    .buttonWithGlassEffect()
                    .frame(width: 44, alignment: .trailing)
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
                    textSizeIndex: textSizeIndex
                )
                // ✅ FIX BUG 2: Quando article.link muda, o SwiftUI descarta e recria
                // o WKWebView do zero — sem reaproveitamento de estado antigo.
                .id(article.link)
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
        // ✅ FIX BUG 2: Reseta isLoading quando a matéria muda
        .onChange(of: article.link) {
            isLoading = true
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
        let zoomScriptSource = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let userScript = WKUserScript(source: zoomScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.isScrollEnabled = true

        // ✅ FIX BUG 2: alpha 0 desde o início via UIKit — nada aparece antes do script rodar
        webView.alpha = 0

        if let url = URL(string: article.link) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // ✅ FIX BUG 1: Re-aplica APENAS o CSS de tema quando colorScheme ou
        // textSizeIndex mudam, sem recarregar a página.
        // O .id(article.link) na view pai garante que mudança de matéria
        // recria o WKWebView inteiro — então aqui só precisamos tratar tema.
        let themeScript = buildThemeOnlyScript()
        if themeScript != context.coordinator.lastThemeScript {
            context.coordinator.lastThemeScript = themeScript
            // Só aplica se a página já carregou
            if !isLoading {
                webView.evaluateJavaScript(themeScript, completionHandler: nil)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, buildScript: buildScript)
    }

    // Script completo: limpeza + header nativo + tema. Roda uma vez no didFinish.
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
            var extractedTitle = '\(fallbackTitle)';
            var extractedCategory = '\(fallbackCategory)';
            var extractedAuthor = '\(fallbackAuthor)';
            var extractedDate = '\(fallbackDate)';

            var titleCandidates = [
                document.querySelector('h1.entry-title'), document.querySelector('h1.post-title'),
                document.querySelector('.entry-header h1'), document.querySelector('.post-header h1'),
                document.querySelector('article h1'), document.querySelector('h1')
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

            ['header', '.container-header-bar', '#breadcrumbs', '#tb-banner-google', 'footer', 'aside', '.sidebar', '.comments-area', '.tb-related', 'nav.tags', '.post-tags'].forEach(function(sel) {
                try { document.querySelectorAll(sel).forEach(el => el.parentNode && el.parentNode.removeChild(el)); } catch(e) {}
            });

            var contentSelectors = ['.entry-content', '.post-content', '.article-content'];
            var content = null;
            for (var i = 0; i < contentSelectors.length; i++) {
                content = document.querySelector(contentSelectors[i]);
                if (content) break;
            }

            if (content) {
                var clone = content.cloneNode(true);
                clone.querySelectorAll('nav.tags, .post-tags').forEach(el => el.remove());
                document.body.innerHTML = '';
                document.body.appendChild(clone);
            }

            var oldHdr = document.getElementById('tb-native-header');
            if (oldHdr) oldHdr.parentNode.removeChild(oldHdr);

            var hdr = document.createElement('div');
            hdr.id = 'tb-native-header';
            hdr.innerHTML = '<div style="padding: 0px 16px 0 16px;"><span style="background:\(accentColor);display:inline-block;color:#fff;font-size:11px;font-weight:700;padding:3px 10px;border-radius:20px;margin-bottom:10px;">' + extractedCategory + '</span><h1 style="font-size:22px;font-weight:700;line-height:1.3;margin:0 0 8px 0;">' + extractedTitle + '</h1><div style="font-size:13px;color:\(textSecColor);">Por ' + extractedAuthor + ' • ' + extractedDate + '</div><div style="height:1px;background:\(borderColor);margin:12px 0 20px 0;"></div></div>';
            document.body.insertBefore(hdr, document.body.firstChild);

            \(buildThemeOnlyScript())
        })();
        """
    }

    // ✅ FIX BUG 1: Só o CSS de tema — usado no updateUIView e embutido no buildScript
    func buildThemeOnlyScript() -> String {
        return """
        (function applyTBTheme() {
            var old = document.getElementById('tb-theme');
            if (old) old.parentNode.removeChild(old);
            var css = 'html, body { background: \(bg) !important; } body { margin: 0 !important; padding: 0 !important; color: \(textColor) !important; font-family: -apple-system, sans-serif !important; font-size: \(fontSizePx)px !important; line-height: 1.75 !important; }';
            css += 'a { color: \(linkColor) !important; text-decoration: none !important; } .entry-content, article { padding: 0 16px 80px 16px !important; }';
            css += 'img { max-width: 100% !important; height: auto !important; border-radius: 8px !important; margin: 12px 0 !important; }';
            css += 'nav.tags, .post-tags { display: none !important; }';
            var s = document.createElement('style');
            s.id = 'tb-theme';
            s.innerHTML = css;
            document.head.appendChild(s);
        })();
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var buildScript: () -> String
        var lastThemeScript: String = ""  // ✅ FIX BUG 1: evita re-aplicar tema igual

        init(isLoading: Binding<Bool>, buildScript: @escaping () -> String) {
            _isLoading = isLoading
            self.buildScript = buildScript
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(buildScript()) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    UIView.animate(withDuration: 0.2) {
                        webView.alpha = 1
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Helpers

extension View {
    func buttonWithGlassEffect() -> some View {
        modifier(ButtonWithGlassEffect())
    }
}

private struct ButtonWithGlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.plain)
                .frame(width: 34, height: 34)
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .buttonStyle(.plain)
                .frame(width: 34, height: 34)
                .font(.system(size: 18, weight: .bold))
        }
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
