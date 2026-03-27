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
            .background(Color.blanco)
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
                                .font(.custom("Barlow", size: 14))
                                .foregroundColor(.negro)
                                .lineLimit(1)
                                .truncationMode(.tail)
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

struct Productos: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    @State private var seccionSeleccionadaId: String = ""
    @State private var scrollTarget: String? = nil

    var body: some View {
        if let comercio = comercioViewModel.comercio {
            let mostrarPromociones = !comercio.promociones.isEmpty && comercio.hayPromocionesDisponibles()
            let secciones: [SeccionComercioNavegacion] = {
                var result: [SeccionComercioNavegacion] = []
                if mostrarPromociones {
                    result.append(SeccionComercioNavegacion(id: "promociones", titulo: "Promociones"))
                }
                for (index, categoria) in comercio.categorias.enumerated() {
                    result.append(SeccionComercioNavegacion(id: "categoria_\(index)", titulo: categoria.nombre))
                }
                return result
            }()

            VStack(spacing: 0) {
                if !secciones.isEmpty {
                    ScrollViewReader { navProxy in
                        NavegacionSeccionesComercio(
                            secciones: secciones,
                            seccionSeleccionadaId: seccionSeleccionadaId,
                            onSeccionSeleccionada: { id in
                                scrollTarget = id
                            }
                        )
                        .onChange(of: seccionSeleccionadaId) { _, newId in
                            withAnimation {
                                navProxy.scrollTo(newId, anchor: .center)
                            }
                        }
                    }
                }

                ScrollViewReader { contentProxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            if mostrarPromociones {
                                TituloPromociones()
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: SectionOffsetKey.self,
                                                value: ["promociones": geo.frame(in: .named("productosScroll")).minY]
                                            )
                                        }
                                    )
                                    .id("promociones")

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

                            ForEach(Array(comercio.categorias.enumerated()), id: \.offset) { index, categoria in
                                let sectionId = "categoria_\(index)"
                                VStack(spacing: 0) {
                                    TituloSeccionComercio(titulo: categoria.nombre)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear.preference(
                                                    key: SectionOffsetKey.self,
                                                    value: [sectionId: geo.frame(in: .named("productosScroll")).minY]
                                                )
                                            }
                                        )
                                        .id(sectionId)

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

                            Spacer().frame(height: 400)
                        }
                    }
                    .coordinateSpace(name: "productosScroll")
                    .onPreferenceChange(SectionOffsetKey.self) { offsets in
                        let threshold: CGFloat = 50
                        if let activeId = offsets
                            .filter({ $0.value < threshold })
                            .max(by: { $0.value < $1.value })?.key {
                            seccionSeleccionadaId = activeId
                        }
                    }
                    .onChange(of: scrollTarget) { _, target in
                        if let target {
                            withAnimation {
                                contentProxy.scrollTo(target, anchor: .top)
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
            .onAppear {
                if seccionSeleccionadaId.isEmpty {
                    seccionSeleccionadaId = secciones.first?.id ?? ""
                }
            }
        }
    }
}

struct TituloSeccionComercio: View {
    let titulo: String
    private let strokeWidth: CGFloat = 3

    var body: some View {
        ZStack {
            // 4 copias en las esquinas forman el contorno
            ForEach([-strokeWidth, strokeWidth], id: \.self) { x in
                ForEach([-strokeWidth, strokeWidth], id: \.self) { y in
                    Text(titulo)
                        .font(.custom("Barlow", size: 30))
                        .bold()
                        .foregroundColor(.grisTerciario)
                        .offset(x: x, y: y)
                }
            }
            // Texto relleno encima
            Text(titulo)
                .font(.custom("Barlow", size: 30))
                .bold()
                .foregroundColor(.blanco)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct TituloPromociones: View {
    var body: some View {
        TituloSeccionComercio(titulo: "Promociones")
    }
}

private struct SeccionComercioNavegacion: Identifiable, Equatable {
    let id: String
    let titulo: String
}

private struct SectionOffsetKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct NavegacionSeccionesComercio: View {
    let secciones: [SeccionComercioNavegacion]
    let seccionSeleccionadaId: String
    let onSeccionSeleccionada: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(secciones) { seccion in
                    let seleccionada = seccion.id == seccionSeleccionadaId
                    Button(action: { onSeccionSeleccionada(seccion.id) }) {
                        Text(seccion.titulo)
                            .font(.custom("Barlow", size: 11))
                            .bold()
                            .foregroundColor(seleccionada ? .blanco : .grisSecundario)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(seleccionada ? Color.verdePrincipal : Color.grisSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .id(seccion.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
