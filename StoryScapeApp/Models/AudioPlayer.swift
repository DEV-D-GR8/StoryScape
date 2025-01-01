//
//  AudioPlayer.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import Foundation
import AVFoundation
import Combine

class AudioPlayer: ObservableObject {
    private var player: AVPlayer?
    
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    private var timeObserver: Any?
    
    func stop() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player?.pause()
        player = nil
        
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1)
        player?.seek(to: cmTime)
    }
    
    func skipForward() {
        guard let currentTime = player?.currentTime().seconds else { return }
        seek(to: currentTime + 5)
    }
    
    func skipBackward() {
        guard let currentTime = player?.currentTime().seconds else { return }
        seek(to: max(0, currentTime - 5))
    }
    
    func playFromData(_ data: Data) {
        stop() // Clear out any existing state
        
        do {
            // Create a temporary file URL
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let tempFileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString + ".mp3")
            
            // Write the audio data to the temporary file
            try data.write(to: tempFileURL)
            
            // Create and play AVPlayer
            let playerItem = AVPlayerItem(url: tempFileURL)
            player = AVPlayer(playerItem: playerItem)
            
            // Observe playback completion
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: nil
            ) { [weak self] _ in
                self?.isPlaying = false
                self?.currentTime = 0
                try? FileManager.default.removeItem(at: tempFileURL)
            }
            
            // Set duration if valid
            let duration = playerItem.asset.duration.seconds
            if duration.isFinite {
                self.duration = duration
            }
            
            // Add time observer to update currentTime
            timeObserver = player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                queue: .main
            ) { [weak self] time in
                self?.currentTime = time.seconds
            }
            
            // Begin playback
            player?.play()
            isPlaying = true
            
        } catch {
            print("Error playing audio: \(error)")
            isPlaying = false
        }
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }
}
