//
//  SeccionDesplegable.swift
//  livery
//
//  Created by Nicolas Matias Garay on 03/01/2026.
//
import SwiftUI

struct SeccionDesplegable<Content: View>: View {
    let titulo: String
    let expandidoInicialmente: Bool
    let backgroundColor: Color
    let contenido: Content

    // Estado interno para manejar la expansión
    @State private var expandido: Bool

    init(
        titulo: String,
        expandidoInicialmente: Bool = false,
        backgroundColor: Color = .blanco,
        @ViewBuilder contenido: () -> Content
    ) {
        self.titulo = titulo
        self.expandidoInicialmente = expandidoInicialmente
        self.backgroundColor = backgroundColor
        self.contenido = contenido()
        // Inicializamos el estado con el valor proporcionado
        _expandido = State(initialValue: expandidoInicialmente)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(titulo)
                    .font(.custom("Barlow", size: 18))
                    .bold()
                    .foregroundColor(.negro)
                    .padding(.leading, 4)

                Spacer()

                // Icono con rotación animada (Flechita)
                Image(systemName: "chevron.down")
                    .font(.custom("Barlow", size: 18))
                    .bold()
                    .foregroundColor(.negro)
                    .rotationEffect(.degrees(expandido ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .onTapGesture {
                expandido.toggle()
            }

            // Contenido expandible
            if expandido {
                VStack {
                    contenido
                }
                .padding(.horizontal, 16)
            }
        }
        .background(backgroundColor)
        .padding(.vertical, 8)
    }
}
