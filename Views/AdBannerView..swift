//
//  AdBannerView..swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 03/04/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//
import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    // ✅ Binding para avisar a View de fora que o Ad falhou
    @Binding var adFailed: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        
        // ID de Teste (Troque pelo seu real ca-app-pub-xxx/yyy depois)
        // Em AdBannerView.swift
        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716" // ID de teste padrão
        banner.backgroundColor = .clear
        
        // ✅ Definimos o delegado para monitorar o carregamento
        banner.delegate = context.coordinator
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            banner.rootViewController = window.rootViewController
        }
        
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    // MARK: - Coordinator (O "vigia" do anúncio)
    class Coordinator: NSObject, BannerViewDelegate {
        var parent: AdBannerView
        init(parent: AdBannerView) { self.parent = parent }

        // Chamado quando o anúncio falha (AdGuard, DNS, etc)
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("ADS: Banner bloqueado ou falhou: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.adFailed = true
            }
        }
        
        // Chamado quando o anúncio carrega com sucesso
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            DispatchQueue.main.async {
                self.parent.adFailed = false
            }
        }
    }
}
