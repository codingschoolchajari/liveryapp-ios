//
//  SplashScreenView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 17/12/2025.
//
import SwiftUI

struct SplashScreenView: View {
    @State private var animacionFinalizada: Bool = false
    
    var body: some View {
        if animacionFinalizada {
            LoginScreenView()
        } else {
            LottieView(animationName: "splash_screen") {
                withAnimation {
                    animacionFinalizada = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                Task{}
            }
        }
    }
}
