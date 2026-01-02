//
//  PedidosEstadosView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 02/01/2026.
//
import SwiftUI

struct PedidosEstadosView: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    
    let estados: [EstadosPedidos] = [
        .todos,
        .pendientes,
        .enPreparacion,
        .enCamino,
        .entregados,
        .cancelados
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            // Primera fila: primeros 3 elementos
            HStack(spacing: 8) {
                ForEach(estados.prefix(3), id: \.self) { estado in
                    EstadoItem(
                        texto: estado.descripcion,
                        seleccionado: estado == pedidosViewModel.estadoSeleccionado,
                        colorSeleccion: estado.color,
                        onClick: { pedidosViewModel.onEstadoSeleccionadoChange(estado: estado) }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            
            // Segunda fila: los restantes
            HStack(spacing: 8) {
                ForEach(estados.suffix(from: 3), id: \.self) { estado in
                    EstadoItem(
                        texto: estado.descripcion,
                        seleccionado: estado == pedidosViewModel.estadoSeleccionado,
                        colorSeleccion: estado.color,
                        onClick: { pedidosViewModel.onEstadoSeleccionadoChange(estado: estado) }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
    }
}

struct EstadoItem: View {
    let texto: String
    let seleccionado: Bool
    let colorSeleccion: Color
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            Text(texto)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(seleccionado ? .blanco : .grisSecundario)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        if seleccionado {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(colorSeleccion)
                        } else {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.grisSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(.grisSecundario, lineWidth: 1)
                                )
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
