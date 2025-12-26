//
//  ProductosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct ProductoMiniatura: View {
    let producto: Producto
    let onMostrarBottomSheet: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? ""))) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.grisSurface
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.blanco)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Rectángulo de descuento
                if let descuento = producto.descuento, descuento > 0 {
                    RectanguloDescuento(producto: producto, redondeado: 12)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: 100, height: 100)
            
            Spacer().frame(height: 4)
            
            Text(producto.nombre)
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 4)
            
            // 3. Precios
            if producto.precio > 0 {
                VStack(spacing: 4) {
                    // Precio actual
                    Text(DoubleUtils.formatearPrecio(valor: producto.precio))
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                    
                    // Precio anterior (tachado)
                    if let descuento = producto.descuento,
                       let precioSinDescuento = producto.precioSinDescuento,
                       descuento > 0
                    {
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(.grisSecundario)
                            .strikethrough(true, color: .grisSecundario)
                    }
                }
                .frame(maxWidth: .infinity)
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
