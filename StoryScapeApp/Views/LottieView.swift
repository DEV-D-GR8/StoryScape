//
//  LottieView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//


import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var filename: String
    var isPlaying: Bool
    
    let animationView = LottieAnimationView()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        animationView.animation = LottieAnimation.named(filename)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = isPlaying ? .loop : .playOnce
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        animationView.animation = LottieAnimation.named(filename)
        animationView.loopMode = isPlaying ? .loop : .playOnce
        if isPlaying {
            animationView.play()
        } else {
            animationView.stop()
        }
    }
}