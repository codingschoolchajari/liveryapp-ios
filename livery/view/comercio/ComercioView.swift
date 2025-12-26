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
            VStack {
                Portada(comercio: comercio)
                Spacer().frame(height: 8)
                InformacionExtra(comercio: comercio)
                Spacer().frame(height: 8)
                Productos(comercioViewModel: comercioViewModel)
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        } else {
            ProgressView()
                .tint(.verdePrincipal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


struct Portada: View {
    let comercio: Comercio
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                AsyncImage(url: URL(string: API.baseURL + "/" + comercio.imagenURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.blanco
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: 180)
            .clipShape(RoundedCorners(radius: 32, corners: [.bottomLeft, .bottomRight]))
            .background(Color.blanco)
            
            VStack {
                ComercioTitulo(
                    comercio: comercio,
                    mostrarPuntuacion: true,
                    mostrarBotonAdd: false,
                    mostrarHorarios: false
                )
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.blanco)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.grisSecundario, lineWidth: 2)
            )
            .padding(.horizontal, 20)
            .offset(y: 100)
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
                                .lineLimit(1)
                                .truncationMode(.tail)
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

struct InformacionExtra: View {
    let comercio: Comercio
    
    @State private var mostrarComentariosSheet = false

    var body: some View {
        VStack(spacing: 4) {
            if let horarios = comercio.horarios {
                Text(DateUtils.obtenerHorariosHoy(horarios: horarios))
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.grisTerciario)
                    .frame(maxWidth: .infinity, alignment: .center)
                    //.padding(.horizontal, 40)
            }
            
            HStack(alignment: .center, spacing: 8) {
                // Icono Ubicación
                Image("icono_ubicacion")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.negro)
                
                // Dirección
                Text(comercio.direccionToString())
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(.negro)
                
                Spacer()
                // Botón Comentarios
                Button(action: {
                    mostrarComentariosSheet = true
                }) {
                    Text("Comentarios")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
        }
        // 3. Bottom Sheet (Equivalente al ModalBottomSheet de Compose)
        .sheet(isPresented: $mostrarComentariosSheet) {
            // Aquí va tu vista de comentarios
            //BottomSheetComentarios(comercio: comercio)
                //.presentationDetents([.large])
        }
    }
}

struct Productos: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    
    var body: some View {
        if let comercio = comercioViewModel.comercio {
            LazyVStack(spacing: 0) {
                
                if !comercio.promociones.isEmpty && comercio.hayPromocionesDisponibles() {
                    TituloPromociones()
                    
                    ForEach(comercio.promociones) { promocion in
                        if promocion.disponible {
                            PromocionTitulo(
                                comercioViewModel: comercioViewModel,
                                promocion: promocion
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                        }
                    }
                }
            
                ForEach(comercio.categorias) { categoria in
                    VStack(spacing: 0) {
                        // Nombre de la Categoría
                        Text(categoria.nombre)
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .foregroundColor(.grisSecundario)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        ForEach(categoria.productos) { producto in
                            if producto.disponible {
                                ProductoTitulo(
                                    comercioViewModel: comercioViewModel,
                                    producto: producto,
                                    categoria: categoria
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100) // Padding bottom = 100.dp
        }
    }
}

struct TituloPromociones: View {
    var body: some View {
        Text("Promociones")
            .font(.custom("Barlow", size: 18))
            .bold()
            .foregroundColor(.grisSecundario)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
