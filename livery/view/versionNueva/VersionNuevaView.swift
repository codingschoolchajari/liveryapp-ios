//
//  VersionNuevaView.swift
//  livery
//
import SwiftUI

struct VersionNuevaView: View {
    var body: some View {
        ZStack {
            Color.blanco.ignoresSafeArea()
            CuadroVersionNueva()
        }
    }
}

struct CuadroVersionNueva: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    var body: some View {
        let url = perfilUsuarioState.configuracion?.plataformas.linkAppStore

        VStack(spacing: 16) {
            Text("Nueva Versión Disponible")
                .font(.custom("Barlow", size: 20))
                .bold()
                .foregroundColor(.verdePrincipal)
                .multilineTextAlignment(.center)

            Image("personaje")
                .resizable()
                .scaledToFit()
                .frame(height: 180)

            Button(action: {
                if let urlStr = url, !urlStr.isEmpty, let appStoreURL = URL(string: urlStr) {
                    UIApplication.shared.open(appStoreURL)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 22))
                    Text("App Store")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                }
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.verdePrincipal)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.verdePrincipal, lineWidth: 4)
        )
        .padding(.horizontal, 40)
    }
}
