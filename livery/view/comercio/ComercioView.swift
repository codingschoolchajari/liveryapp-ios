//
//  ComercioView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 24/12/2025.
//
import SwiftUI

struct ComercioView: View {
    @StateObject var comercioViewModel : ComercioViewModel
    
    var body: some View {
        if let comercio = comercioViewModel.comercio {
            ComercioTitulo(comercio: comercio)
        } else {
            ProgressView()
                .tint(.verdePrincipal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ComercioTitulo: View {
    let comercio: Comercio
    var mostrarPuntuacion: Bool = true
    var mostrarBotonAdd: Bool = false
    var mostrarHorarios: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Horarios (Alineado a la derecha arriba)
            if mostrarHorarios, let horarios = comercio.horarios {
                HStack {
                    Spacer()
                    Text(DateUtils.obtenerHorariosHoy(horarios: horarios))
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.grisTerciario)
                }
            }
            
            HStack(alignment: .center) {
                
                // Grupo Izquierdo: Logo + Nombre/Categorías
                HStack(spacing: 14) {
                    // Box equivalente: AsyncImage con clip
                    AsyncImage(url: URL(string: API.baseURL + "/" + comercio.logoURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.grisSurface
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comercio.nombre)
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .foregroundColor(.negro)
                        
                        if !comercio.categoriasPrincipales.isEmpty {
                            Text(comercio.categoriasPrincipalesToString())
                                .font(.custom("Barlow", size: 16))
                                .foregroundColor(.negro)
                        }
                    }
                }
                
                Spacer()
                
                // Grupo Derecho: Estrella + Puntuación o Botón Add
                HStack(spacing: 8) {
                    if mostrarPuntuacion {
                        Image("icono_estrella_relleno")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text(String(format: "%.1f", comercio.puntuacion))
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .foregroundColor(.negro)
                    }
                    
                    if mostrarBotonAdd {
                        if mostrarPuntuacion {
                            Image("icono_add_circle")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
    }
}
