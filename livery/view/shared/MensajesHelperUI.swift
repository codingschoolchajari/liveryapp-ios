//
//  MensajesHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//

import SwiftUI

struct ToastView: View {
    @Binding var mensaje: String?
    
    var body: some View {
        if let texto = mensaje {
            Text(texto)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    Capsule().fill(Color.black)
                )
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
        }
    }
}
