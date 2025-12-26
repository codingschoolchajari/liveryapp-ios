//
//  CarritoHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct TituloComercio: View {
    let comercio: Comercio
    
    var body: some View {
        ZStack {
            ComercioTitulo(
                comercio: comercio,
                mostrarPuntuacion: false,
                mostrarBotonAdd: true
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color.blanco)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.grisSecundario, lineWidth: 2)
        )
        .padding(.horizontal, 30)
    }
}
