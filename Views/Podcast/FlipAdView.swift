//
//  FlipAdView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 05/04/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import Combine // Corrigido: import padrão

struct FlipAdView: View {
    let episode: PodcastEpisode
    @Binding var isPlaying: Bool
    @State private var showAd = false
    @State private var adFailed = false
    @AppStorage("isAdFree") private var isAdFree = false
    
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            artworkImage
                .rotation3DEffect(.degrees(showAd ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(showAd ? 0 : 1)

            if !isAdFree {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                    
                    if adFailed {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill").foregroundStyle(TBTheme.accent)
                            Text("Apoie o Tecnoblog").font(.caption2).multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        AdBannerView(adFailed: $adFailed)
                            .frame(width: 320, height: 50)
                            .scaleEffect(0.8)
                    }
                }
                .frame(width: 240, height: 240)
                .rotation3DEffect(.degrees(showAd ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(showAd ? 1 : 0)
            }
        }
        .onReceive(timer) { _ in
            if !isAdFree && isPlaying {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showAd.toggle()
                }
                
                if showAd {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        withAnimation(.spring()) { showAd = false }
                    }
                }
            }
        }
    }

    private var artworkImage: some View {
        AsyncImage(url: URL(string: episode.artworkURL)) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                placeholderArtwork
            }
        }
        .frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: TBTheme.accent.opacity(0.3), radius: 20, y: 8)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(TBTheme.highlightGradient)
            Image(systemName: "mic.fill").font(.system(size: 64)).foregroundStyle(.white)
        }
    }
}
