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
    @Binding var adFailed: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> BannerView {
        // Correção: Inicialização correta do tamanho do banner
        let banner = BannerView(adSize: AdSizeBanner)
        
        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        banner.backgroundColor = .clear
        banner.delegate = context.coordinator
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            banner.rootViewController = window.rootViewController
        }
        
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: AdBannerView
        init(parent: AdBannerView) { self.parent = parent }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("ADS Error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.adFailed = true
            }
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            DispatchQueue.main.async {
                self.parent.adFailed = false
            }
        }
    }
}
