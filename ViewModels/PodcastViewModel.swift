//
//  PodcastViewModel.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData
import AVFoundation
import MediaPlayer

@MainActor
@Observable
final class PodcastViewModel {
    // MARK: - Properties
    var episodes: [PodcastEpisode] = []
    var isLoading = false
    var errorMessage: String?
    var channelArtworkURL = ""

    // Atualiza o Now Playing e inicia o play quando o episódio muda
    var currentEpisode: PodcastEpisode? {
        didSet {
            if let episode = currentEpisode {
                updateNowPlayingInfo()
                if !isPlaying {
                    play(episode)
                }
            }
        }
    }
    
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0

    private let feedService = FeedService()
    private var modelContext: ModelContext?
    private var player: AVPlayer?
    private var timeObserver: Any?

    // MARK: - Setup
    func setup(context: ModelContext) {
        self.modelContext = context
        setupAudioSession()
        setupRemoteCommandCenter()
    }

    // MARK: - Load Episodes
    func loadEpisodes() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let (items, artworkURL) = try await feedService.fetchPodcasts()
            channelArtworkURL = artworkURL
            var loadedEpisodes: [PodcastEpisode] = []

            if let context = modelContext {
                for item in items {
                    let id = item.guid.isEmpty ? item.audioURL : item.guid
                    let descriptor = FetchDescriptor<PodcastEpisode>(predicate: #Predicate { $0.id == id })
                    
                    if let existing = try? context.fetch(descriptor).first {
                        loadedEpisodes.append(existing)
                    } else {
                        let newEpisode = PodcastEpisode(
                            id: id, title: item.title, audioURL: item.audioURL,
                            pubDate: item.pubDate, duration: item.audioDuration,
                            thumbnailURL: item.thumbnailURL, channelArtworkURL: artworkURL,
                            summary: item.excerpt
                        )
                        context.insert(newEpisode)
                        loadedEpisodes.append(newEpisode)
                    }
                }
                try? context.save()
                withAnimation { self.episodes = loadedEpisodes }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Playback Logic
    func play(_ episode: PodcastEpisode) {
        if currentEpisode?.id == episode.id && player != nil {
            togglePlayPause()
            return
        }

        stopPlayer()
        currentEpisode = episode
        
        guard let url = URL(string: episode.audioURL) else {
            errorMessage = "URL de áudio inválida."
            return
        }

        setupAudioSession()

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true

        if episode.playbackPosition > 0 {
            player?.seek(to: CMTime(seconds: episode.playbackPosition, preferredTimescale: 1))
        }

        player?.play()
        isPlaying = true
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let d = self.player?.currentItem?.duration.seconds, !d.isNaN, d > 0 {
                self.duration = d
            }
            // Salva posição no SwiftData
            self.currentEpisode?.playbackPosition = self.currentTime
            self.updatePlaybackMetadata()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(episodeDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration))
        player?.seek(to: CMTime(seconds: clamped, preferredTimescale: 1))
        currentTime = clamped
        updateNowPlayingInfo()
    }
    
    func skipForward(seconds: Double = 30) { seek(to: currentTime + seconds) }
    func skipBackward(seconds: Double = 15) { seek(to: currentTime - seconds) }

    func toggleFavorite(_ episode: PodcastEpisode) {
        episode.isFavorite.toggle()
        try? modelContext?.save()
    }

    // MARK: - Private Helpers & Remote Center
    private func stopPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
    }

    @objc private func episodeDidFinish() {
        isPlaying = false
        currentTime = 0
        currentEpisode?.playbackPosition = 0
        try? modelContext?.save()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erro ao configurar AVAudioSession: \(error)")
        }
    }

    // ✅ CORREÇÃO: Método restaurado
    func updateNowPlayingInfo() {
        guard let episode = currentEpisode else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: episode.title,
            MPMediaItemPropertyArtist: "Tecnocast",
            MPMediaItemPropertyAlbumTitle: "Tecnoblog",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let artworkURL = URL(string: channelArtworkURL),
           let data = try? Data(contentsOf: artworkURL),
           let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // ✅ CORREÇÃO: Método restaurado
    func updatePlaybackMetadata() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // ✅ CORREÇÃO: Método restaurado
    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        
        center.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
        
        center.skipForwardCommand.preferredIntervals = [30]
        center.skipBackwardCommand.preferredIntervals = [15]
    }
}
