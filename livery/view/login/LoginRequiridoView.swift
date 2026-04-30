//
//  LoginRequiridoView.swift
//  livery
//
//  Created by Nicolas Matias Garay.
//
import SwiftUI

/// Sheet reutilizable que se muestra cuando el usuario intenta una acción que requiere sesión iniciada.
struct LoginRequiridoView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Image("personaje")
                .resizable()
                .scaledToFit()
                .frame(width: 200)

            Spacer().frame(height: 24)

            Text("Para acceder a esta funcionalidad es necesario iniciar sesión")
                .font(.custom("Barlow", size: 20))
                .bold()
                .foregroundColor(.negro)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: 32)

            SignInView()

            Spacer().frame(height: 16)

            Button(action: onDismiss) {
                Text("Ahora no")
                    .font(.custom("Barlow", size: 16))
                    .foregroundColor(.grisSecundario)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
    }
}
