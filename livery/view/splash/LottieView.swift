//
//  LottieView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 17/12/2025.
//
import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var animationName: String
    var loopMode: LottieLoopMode = .playOnce
    var completion: (() -> Void)? = nil

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .verdeSplashScreen

        let animationView = LottieAnimationView(name: animationName)

        if UIDevice.current.userInterfaceIdiom == .pad {
            // En iPad usamos .scaleAspectFit para evitar que se corte
            // ya que la pantalla es más cuadrada (4:3)
            animationView.contentMode = .scaleAspectFit
        } else {
            // En iPhone usamos .scaleAspectFill para llenar toda la pantalla
            // aprovechando que la animación es 9:16 (vertical)
            animationView.contentMode = .scaleAspectFill
        }
        animationView.loopMode = loopMode
        

        animationView.play { finished in
            if finished {
                completion?()
            }
        }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

