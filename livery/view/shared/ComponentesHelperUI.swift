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

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(configuration.isOn ? .verdePrincipal : .grisSecundario) // Usa tus colores
        }
        .buttonStyle(PlainButtonStyle()) // Evita el efecto de resaltado gris de los botones
    }
}

@ViewBuilder
func opcionBoton(
    titulo: String,
    esSeleccionado: Bool,
    radius: RectangleCornerRadii,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Text(titulo)
            .font(.custom("Barlow", size: 14))
            .bold()
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .foregroundColor(esSeleccionado ? .verdePrincipal : .negro)
            .background(esSeleccionado ? .grisSurface : .blanco)
            .clipShape(UnevenRoundedRectangle(cornerRadii: radius))
            .overlay(
                UnevenRoundedRectangle(cornerRadii: radius)
                    .stroke(Color.grisSecundario, lineWidth: 2)
            )
    }
    .buttonStyle(.plain)
}
