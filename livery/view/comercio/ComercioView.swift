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
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @State private var categoriaSeleccionadaId: String? = nil
    @State private var mostrarComentarios = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let comercio = comercioViewModel.comercio {
                VStack(spacing: 0) {
                    Portada(
                        comercio: comercio,
                        onComentariosTap: { mostrarComentarios = true }
                    )
                    Spacer().frame(height: 8)
                    InformacionExtra(
                        comercio: comercio,
                        categoriaSeleccionadaId: $categoriaSeleccionadaId
                    )
                    Spacer().frame(height: 8)
                    Productos(
                        comercioViewModel: comercioViewModel,
                        categoriaSeleccionadaId: categoriaSeleccionadaId
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
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
        .sheet(isPresented: $mostrarComentarios) {
            if let comercio = comercioViewModel.comercio {
                BottomSheetComentarios(
                    comercio: comercio,
                    perfilUsuarioState: perfilUsuarioState
                )
            }
        }
    }
}


struct Portada: View {
    let comercio: Comercio
    var onComentariosTap: () -> Void = {}
    
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
                        mostrarHorarios: false,
                        mostrarBotonComentarios: true,
                        onComentariosTap: onComentariosTap
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
    var mostrarBotonComentarios: Bool = false
    var onComentariosTap: () -> Void = {}
    
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
                        HStack(alignment: .center, spacing: 10) {
                            Text(comercio.nombre)
                                .font(.custom("Barlow", size: 18))
                                .bold()
                                .foregroundColor(.negro)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if mostrarBotonComentarios {
                                Button(action: onComentariosTap) {
                                    Image("icono_comentarios")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(.negro)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
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
    @Binding var categoriaSeleccionadaId: String?

    private var horariosReducidos: [ComercioHorarioReducido] {
        (comercio.horariosReducidos ?? []).filter {
            !$0.descripcion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 4) {
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
                if let horarios = comercio.horarios {
                    Text(DateUtils.obtenerHorariosHoy(horarios: horarios))
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.grisTerciario)
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)

            if !horariosReducidos.isEmpty {
                ForEach(horariosReducidos, id: \.idInterno) { horarioReducido in
                    Divider()
                        .padding(.horizontal, 40)

                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "clock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.negro)

                        Text(horarioReducido.descripcion)
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(.negro)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(DateUtils.obtenerHorariosReducidosHoy(horarioReducido: horarioReducido))
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(.grisTerciario)
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 4)
            }
            
            SelectorCategoriasComercio(
                categorias: comercio.categorias,
                categoriaSeleccionadaId: $categoriaSeleccionadaId
            )
        }
    }
}

struct SelectorCategoriasComercio: View {
    let categorias: [Categoria]
    @Binding var categoriaSeleccionadaId: String?

    private var categoriaSeleccionadaNombre: String {
        guard let categoriaSeleccionadaId,
              let categoria = categorias.first(where: { $0.idInterno == categoriaSeleccionadaId }) else {
            return "Todas las categorías"
        }

        return categoria.nombre
    }

    var body: some View {
        Menu {
            Button {
                categoriaSeleccionadaId = nil
            } label: {
                Text("Todas las categorías")
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            ForEach(categorias) { categoria in
                Button {
                    categoriaSeleccionadaId = categoria.idInterno
                } label: {
                    Text(categoria.nombre)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        } label: {
            ZStack {
                Text(categoriaSeleccionadaNombre)
                    .font(.custom("Barlow", size: 12))
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)

                HStack {
                    Spacer()
                    Image("icono_flecha_abajo")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 10)
            .background(Color.blanco)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 2)
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
    let categoriaSeleccionadaId: String?

    var body: some View {
        if let comercio = comercioViewModel.comercio {
            let mostrarPromociones = !comercio.promociones.isEmpty && comercio.hayPromocionesDisponibles()

            let avisoHabilitado = comercio.aviso.habilitado && !comercio.aviso.mensaje.isEmpty

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id("top")

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

                        ForEach(comercio.categorias) { categoria in
                            let productosDisponibles = categoria.productos.filter { $0.disponible && $0.esComplemento != true }
                            if !productosDisponibles.isEmpty {
                                VStack(spacing: 0) {
                                    TituloSeccionComercio(titulo: categoria.nombre)
                                        .id(categoria.idInterno)

                                    ForEach(productosDisponibles) { producto in
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
                .clipped()
                .onChange(of: categoriaSeleccionadaId) { _, newValue in
                    if let newValue {
                        proxy.scrollTo(newValue, anchor: .top)
                    } else {
                        proxy.scrollTo("top", anchor: .top)
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
