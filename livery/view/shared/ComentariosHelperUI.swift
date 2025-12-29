//
//  ComentariosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 29/12/2025.
//
import SwiftUI

struct BottomSheetComentarios: View {
    let comercio: Comercio
    
    var body: some View {
        
        VStack(spacing: 8) {
            Spacer().frame(height: 16)
            TituloComercio(
                comercio: comercio,
                mostrarPuntuacion: true,
                mostrarBotonAdd: false
            )
            Spacer()
        }
    }
}
