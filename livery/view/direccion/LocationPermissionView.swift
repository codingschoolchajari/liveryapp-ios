//
//  LocationPermissionView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 05/01/2026.
//
import SwiftUI

struct LocationPermissionView: View {

    var body: some View {
        
        VStack(spacing: 12){
            Text("Su ubicación es necesaria para poder mostrarles los comercios de su ciudad y permitirle al repartidor entregar su pedido más rápidamente. \n\n Por favor abra los ajustes para dar permisos de ubicación.")
                .padding(.horizontal, 24)
                .font(.custom("Barlow", size: 18))
                .bold()
                .frame(maxWidth: .infinity)
                .foregroundColor(.negro)
                .multilineTextAlignment(.center)
                
            Button {
                openAppSettings()
            } label : {
                Text("Abrir Ajustes")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .frame(width: 250, height: 40)
                    .foregroundColor(.blanco)
                    .background(.verdePrincipal)
                    .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
