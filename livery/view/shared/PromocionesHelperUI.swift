//
//  PromocionesHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct PromocionMiniatura: View {
    let promocion: Promocion
    let onMostrarBottomSheet: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack {
                AsyncImage(url: URL(string: API.baseURL + "/" + promocion.imagenURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.grisSurface // Placeholder
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.blanco)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(width: 100, height: 100)
            
            Spacer().frame(height: 4)
            
            // 2. Nombre de la Promoción
            Text(promocion.nombre)
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 4)
            
            // 3. Precio
            if promocion.precio > 0 {
                Text(DoubleUtils.formatearPrecio(valor: promocion.precio))
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
        }
        .frame(width: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onMostrarBottomSheet()
        }
    }
}
