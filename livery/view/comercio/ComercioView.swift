//
//  ComercioView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 24/12/2025.
//
import SwiftUI

struct ComercioView: View {
    @StateObject var comercioViewModel : ComercioViewModel
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let comercio = comercioViewModel.comercio {
                VStack {
                    Portada(comercio: comercio)
                    Spacer().frame(height: 8)
                    InformacionExtra(comercio: comercio)
                    Spacer().frame(height: 8)
                    Productos(comercioViewModel: comercioViewModel)
                    Spacer()
                }
                .background(Color.blanco)
                .ignoresSafeArea(edges: .top)

                BannerAviso(comercioViewModel: comercioViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ProgressView()
                    .tint(.verdePrincipal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                comercioViewModel.refreshCategoriasYPromociones()
            }
        }
    }
}


struct Portada: View {
    let comercio: Comercio
    
    private var descuentosFiltrados: [ComercioDescuento] {
        (comercio.descuentos ?? []).filter { $0.porcentaje > 0.0 }
    }
    
    var body: some View {
        // offsetY = 100 para 0 descuentos; se eleva 46pt por cada descuento (44 height + 2 spacing)
        let descuentos = descuentosFiltrados
        let offsetY: CGFloat = 100 - CGFloat(descuentos.count) * 46
        
        ZStack(alignment: .top) {
            VStack {
                RemoteImage(url: URL(string: API.baseURL + "/" + comercio.imagenURL))
            }
            .frame(width: UIScreen.main.bounds.width, height: 180)
            .clipShape(RoundedCorners(radius: 32, corners: [.bottomLeft, .bottomRight]))
            .background(Color.blanco)

            // Título + descuentos en una sola columna anclada al fondo (igual que Android)
            VStack(spacing: 4) {
                VStack {
                    ComercioTitulo(
                        comercio: comercio,
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

                ForEach(Array(descuentos.enumerated()), id: \.offset) { _, descuento in
                    BoxDescuentoPortada(descuento: descuento)
                }
            }
            .padding(.horizontal, 20)
            .offset(y: offsetY)
        }
    }
}

private struct BoxDescuentoPortada: View {
    let descuento: ComercioDescuento

    var body: some View {
        let porcentajeTexto = descuento.porcentaje.truncatingRemainder(dividingBy: 1.0) == 0
            ? "\(Int(descuento.porcentaje))"
            : "\(descuento.porcentaje)"

        Text("\(descuento.descripcion) (\(porcentajeTexto)%)")
            .font(.custom("Barlow", size: 13))
            .bold()
            .foregroundColor(.verdePrincipal)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(Color.blanco)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.grisSecundario, lineWidth: 2)
            )
    }
}

struct ComercioTitulo: View {
    let comercio: Comercio
    var mostrarBotonAdd: Bool = false
    var mostrarHorarios: Bool = false
    var mostrarEncabezado: Bool = false
    var mostrarSubtituloDistancia: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if mostrarEncabezado, let horarios = comercio.horarios {
                HStack {
                    // Distancia al usuario
                    if let distancia = comercio.distanciaUsuario {
                        Text("A  \(distancia)  metros")
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(.grisTerciario)
                    }
                    
                    Spacer()
                    
                    // Horarios
                    Text(DateUtils.obtenerHorariosHoy(horarios: horarios))
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(.grisTerciario)
                }
                Spacer().frame(height: 4)
            }
            
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
                    RemoteImage(url: URL(string: API.baseURL + "/" + comercio.logoURL))
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
                                .font(.custom("Barlow", size: 14))
                                .foregroundColor(.negro)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if mostrarSubtituloDistancia, let distancia = comercio.distanciaUsuario, distancia > 0 {
                            Text("A  \(distancia)  metros")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                                .foregroundColor(.grisTerciario)
                        }
                    }
                }
                
                Spacer()
                
                // Grupo Derecho
                HStack(spacing: 8) {
                    if mostrarBotonAdd {
                        Image("icono_add_circle")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.negro)
                    }
                }
            }
        }
    }
}

struct InformacionExtra: View {
    let comercio: Comercio
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var mostrarComentariosSheet = false

    var body: some View {
        VStack(spacing: 4) {
            if let horarios = comercio.horarios {
                Text(DateUtils.obtenerHorariosHoy(horarios: horarios))
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.grisTerciario)
                    .frame(maxWidth: .infinity, alignment: .center)
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
        
        .sheet(isPresented: $mostrarComentariosSheet) {
            // Aquí va tu vista de comentarios
            BottomSheetComentarios(
                comercio: comercio,
                perfilUsuarioState: perfilUsuarioState
            )
                .presentationDetents([.large])
        }
    }
}

struct BannerAviso: View {
    @ObservedObject var comercioViewModel: ComercioViewModel

    var body: some View {
        let aviso = comercioViewModel.comercio?.aviso
        if aviso?.habilitado == true, let mensaje = aviso?.mensaje, !mensaje.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
                Text(mensaje)
                    .font(.custom("Barlow", size: 13))
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.verdePrincipal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct Productos: View {
    @ObservedObject var comercioViewModel: ComercioViewModel

    var body: some View {
        if let comercio = comercioViewModel.comercio {
            let mostrarPromociones = !comercio.promociones.isEmpty && comercio.hayPromocionesDisponibles()

            let avisoHabilitado = comercio.aviso.habilitado && !comercio.aviso.mensaje.isEmpty

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if mostrarPromociones {
                        VStack(spacing: 0) {
                            TituloPromociones()

                            ForEach(comercio.promociones) { promocion in
                                if promocion.disponible {
                                    PromocionTitulo(
                                        comercioViewModel: comercioViewModel,
                                        promocion: promocion,
                                        onSelect: {
                                            comercioViewModel.seleccionarPromocion(promocion: promocion)
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    ForEach(Array(comercio.categorias.enumerated()), id: \.offset) { _, categoria in
                        VStack(spacing: 0) {
                            TituloSeccionComercio(titulo: categoria.nombre)

                            ForEach(categoria.productos) { producto in
                                if producto.disponible {
                                    ProductoTitulo(
                                        comercioViewModel: comercioViewModel,
                                        producto: producto,
                                        categoria: categoria,
                                        onSelect: {
                                            comercioViewModel.seleccionarProducto(
                                                producto: producto,
                                                categoria: categoria
                                            )
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    if avisoHabilitado {
                        Spacer().frame(height: 64)
                    }
                }
            }
            .sheet(item: $comercioViewModel.promocionSeleccionada) { promocion in
                BottomSheetSeleccionPromocion(
                    promocion: promocion,
                    comercio: comercio,
                    onClose: {
                        comercioViewModel.limpiarSeleccionado()
                    }
                )
                .onDisappear {
                    comercioViewModel.limpiarSeleccionado()
                }
            }
            .sheet(item: $comercioViewModel.productoSeleccionado) { productoSeleccionado in
                if (comercioViewModel.categoria != nil){
                    BottomSheetSeleccionProducto(
                        producto: productoSeleccionado,
                        categoria: comercioViewModel.categoria!,
                        comercio: comercio,
                        onClose: {
                            comercioViewModel.limpiarSeleccionado()
                        }
                    )
                    .onDisappear {
                        comercioViewModel.limpiarSeleccionado()
                    }
                }
            }
        }
    }
}

struct TituloSeccionComercio: View {
    let titulo: String

    var body: some View {
        Text(titulo)
            .font(.custom("Barlow", size: 28))
            .bold()
            .foregroundColor(.grisTerciario)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct TituloPromociones: View {
    var body: some View {
        TituloSeccionComercio(titulo: "Promociones")
    }
}
