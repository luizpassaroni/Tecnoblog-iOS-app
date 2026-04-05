//
//  AdInterstitialHandler.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 03/04/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import GoogleMobileAds
import SwiftUI

@Observable
class AdRewardedHandler: NSObject, FullScreenContentDelegate {
    var rewardedAd: RewardedAd?
    private var isAdReady: Bool = false
    
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    func loadAd() {
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { ad, error in
            if let error = error {
                self.isAdReady = false
                return
            }
            self.rewardedAd = ad
            self.isAdReady = true
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    func showAd(onReward: @escaping () -> Void, onFailure: @escaping () -> Void) {
        // Se o AdGuard bloqueou ou não carregou, chamamos o onFailure
        guard let rewardedAd = rewardedAd else {
            onFailure()
            loadAd()
            return
        }
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            
            rewardedAd.present(from: rootVC) {
                // ✅ ESTE É O ÚNICO LUGAR QUE LIBERA A MATÉRIA
                // Só roda se o Google confirmar que o vídeo terminou
                onReward()
            }
        } else {
            onFailure()
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadAd()
    }
}
