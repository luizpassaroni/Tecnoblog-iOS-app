
//
//  AdInterstitialHandler.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 03/04/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import GoogleMobileAds
import SwiftUI

// Remova o @Observable se ele estiver causando conflito com o NSObject em sua versão
// Caso contrário, mantenha-o para o funcionamento da UI
@Observable
class AdRewardedHandler: NSObject, FullScreenContentDelegate {
    var rewardedAd: RewardedAd?
    
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    @MainActor
    func loadAd() {
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Erro ao carregar anúncio: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    @MainActor
    func showAd(onReward: @escaping () -> Void, onFailure: @escaping () -> Void) {
        guard let rewardedAd = rewardedAd else {
            onFailure()
            loadAd()
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            rewardedAd.present(from: rootVC) {
                onReward()
            }
        } else {
            onFailure()
        }
    }
    
    // MARK: - FullScreenContentDelegate (Correção Swift 6)
    
    // Usamos nonisolated para conformar ao protocolo exigido pelo SDK do Google
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Como loadAd() é @MainActor, precisamos disparar uma Task
        Task { @MainActor in
            loadAd()
        }
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Falha ao apresentar anúncio: \(error.localizedDescription)")
        Task { @MainActor in
            loadAd()
        }
    }
}
