//
//  HomeView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject var homeViewModel : HomeViewModel
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            
            FranjaPrincipal()
            BusquedaModos(homeViewModel: homeViewModel)
            
            if  ( perfilUsuarioState.ciudadSeleccionada != nil
                  && perfilUsuarioState.ciudadSeleccionada == StringUtils.sinCobertura
                ) || (
                    perfilUsuarioState.usuario != nil
                    && perfilUsuarioState.usuario!.direcciones?.isEmpty ?? true
                )
            {
                DireccionFueraDeCobertura()
            } else {
                if homeViewModel.modoComercioSeleccionado {
                    SelectorCategorias(homeViewModel: homeViewModel)
                    Spacer().frame(height: 8)
                    ListaComercios(homeViewModel: homeViewModel)
                } else {
                    FranjaBusqueda(homeViewModel: homeViewModel)
                    ListaComerciosProductos(homeViewModel: homeViewModel)
                }
            }
        }
        .padding(.bottom, 16)
        .background(Color.blanco)
    }
}

struct FranjaPrincipal: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var notificacionesState: NotificacionesState
    @EnvironmentObject var navManager: NavigationManager

    @State private var mostrarDirecciones = false
    @State private var mostrarNotificaciones = false

    var body: some View {
        HStack {

            Button {
                mostrarDirecciones = true
            } label: {
                HStack(spacing: 6) {
                    Text(
                        perfilUsuarioState.idDireccionSeleccionada?.isEmpty ?? true
                        ? "Seleccionar dirección"
                        : perfilUsuarioState.obtenerDireccionSeleccionada()
                    )
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.blanco)

                    Image("icono_flecha_abajo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {

                Button {
                    mostrarNotificaciones = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_notificaciones")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blanco)
                            .overlay(alignment: .topTrailing) {
                                if !notificacionesState.notificacionesNoLeidas.isEmpty {
                                    Text("\(notificacionesState.notificacionesNoLeidas.count)")
                                        .font(.custom("Barlow", size: 12))
                                        .bold()
                                        .foregroundColor(.blanco)
                                        .frame(width: 22, height: 22)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 10, y: -8)
                                }
                            }
                    }
                }

                Button {
                    //NavigationManager.shared.navigate("premios")
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_premios")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blanco)
                        
                        let giros = perfilUsuarioState.usuario?.premios?.girosRestantes
                        if let giros, giros > 0 {
                            //BadgeView(count: giros)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(.verdePrincipal)
        .sheet(isPresented: $mostrarDirecciones) {
            BottomSheetDirecciones(
                onNuevaDireccion: {
                    mostrarDirecciones = false
                    navManager.irADireccion()
                },
                onDireccionSeleccionada: {
                    mostrarDirecciones = false
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $mostrarNotificaciones) {
            BottomSheetNotificaciones(
                onNotificacionClick: { idPedido in
                    mostrarNotificaciones = false
                }
            )
            .onDisappear {
                notificacionesState.marcarTodasComoLeidas()
            }
        }
    }
}

struct BusquedaModos: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        HStack {
            // Contenedor blanco
            HStack(spacing: 16) {

                Button {
                    homeViewModel.onModoComercioSeleccionadoChange(true)
                } label: {
                    Image("icono_busqueda_comercios")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(
                            homeViewModel.modoComercioSeleccionado
                            ? .verdePrincipal
                            : .grisSecundario
                        )
                }
                .buttonStyle(.plain)

                Button {
                    homeViewModel.onModoComercioSeleccionadoChange(false)
                } label: {
                    Image("icono_busqueda_productos")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(
                            !homeViewModel.modoComercioSeleccionado
                            ? .verdePrincipal
                            : .grisSecundario
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.verdePrincipal)
        .clipShape(
            RoundedCorners(
                radius: homeViewModel.modoComercioSeleccionado ? 32 : 0,
                corners: [.bottomLeft, .bottomRight]
            )
        )
        .animation(.easeInOut, value: homeViewModel.modoComercioSeleccionado)
    }
}

struct FranjaBusqueda: View {
    @ObservedObject var homeViewModel: HomeViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color.verdePrincipal)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .clipShape(RoundedCorners(radius: 32, corners: [.bottomLeft, .bottomRight]))
            
            Buscador(homeViewModel: homeViewModel)
                .offset(y: 5)
        }
        .zIndex(100)
    }
}

struct Buscador: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var estaExpandido = false
        
    var body: some View {
        let configuracion = perfilUsuarioState.configuracion
        let palabrasClave = configuracion?.palabrasClave.map { $0.capitalized } ?? []
        
        let palabraSeleccionada = homeViewModel.palabraClaveSeleccionada
        let placeholder = (palabraSeleccionada?.isEmpty ?? true) ? "¿Qué se te antoja hoy?" : palabraSeleccionada!.capitalized

        HStack {
            Text(placeholder)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(Color.grisSecundario)
            Spacer()
            Image(systemName: estaExpandido ? "chevron.up" : "chevron.down")
                .foregroundColor(Color.grisSecundario)
                .font(.custom("Barlow", size: 14))
                .bold()
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
        .background(Color.blanco)
        .clipShape(RoundedCorners(
            radius: 32,
            corners: estaExpandido ? [.topLeft, .topRight] : .allCorners
        ))
        .onTapGesture {
            withAnimation(.spring()) {
                estaExpandido.toggle()
            }
        }
        .overlay(alignment: .top) {
            if estaExpandido {
                VStack(spacing: 0) {
                    // Este espacio vacío empuja la lista exactamente debajo del botón blanco
                    Color.clear.frame(height: 44)
                    
                    VStack(spacing: 0) {
                        Divider().background(Color.grisSecundario)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(palabrasClave, id: \.self) { palabra in
                                    Button(action: {
                                        homeViewModel.onPalabraClaveSeleccionadaChange(palabra)
                                        withAnimation { estaExpandido = false }
                                    }) {
                                        Text(palabra)
                                            .font(.custom("Barlow", size: 14))
                                            .bold()
                                            .foregroundColor(.negro)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .background(Color.blanco)
                    .clipShape(RoundedCorners(radius: 22, corners: [.bottomLeft, .bottomRight]))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 24)
        .zIndex(100)
    }
}

struct SelectorCategorias: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(ListUtils.categorias, id: \.idInterno) { categoria in
                        VStack {
                            Button {
                                homeViewModel.onCategoriaSeleccionadaChange(categoria.idInterno)
                            } label: {
                                Image(categoria.imagenGenerica!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 60)
                                    .padding(.all, 2)
                                    .background(.grisSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                homeViewModel.categoriaSeleccionada == categoria.idInterno
                                                ? .verdePrincipal
                                                : .clear,
                                                lineWidth: 4
                                            )
                                    )
                            }
                            
                            Text(categoria.nombre)
                                .font(.custom("Barlow", size: 11))
                                .bold()
                                .foregroundColor(.negro)
                        }
                        .id(categoria.idInterno)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
            .onChange(of: homeViewModel.categoriaSeleccionada) { oldValue, newValue in
                withAnimation(.spring()) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onAppear {
                if let seleccionada = homeViewModel.categoriaSeleccionada, !seleccionada.isEmpty {
                    // Damos un respiro de 0.1 o 0.2 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring()) {
                            proxy.scrollTo(seleccionada, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

struct ListaComercios: View {
    @ObservedObject var homeViewModel: HomeViewModel
    
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(homeViewModel.comercios) { comercio in
                    TarjetaComercio(comercio: comercio)
                        .padding(.horizontal, 16)
                        .onAppear {
                            if comercio.idInterno == homeViewModel.comercios.last?.idInterno {
                                Task {
                                    await homeViewModel.cargarMasComercios()
                                }
                            }
                        }
                        .onTapGesture {
                            navManager.homePath.append(NavigationManager.HomeDestination.comercio(idComercio: comercio.idInterno))
                        }
                }
            }
        }
    }
}

struct TarjetaComercio: View {
    let comercio: Comercio

    var body: some View {
        VStack(spacing: 0) {
            // Mitad Superior: Imagen
            AsyncImage(url: URL(string: API.baseURL + "/" + comercio.imagenURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fondo vacío o color base mientras carga/falla
                    Color.grisSurface
                }
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .clipped()

            // Mitad Inferior:
            ComercioTitulo(comercio: comercio, mostrarHorarios: true)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .background(Color.grisSurface)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }
}

struct ListaComerciosProductos: View {
    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        let comerciosProductos = homeViewModel.comerciosProductos
        
        ScrollView (showsIndicators: false){
            LazyVStack(spacing: 4) {
                ForEach(comerciosProductos, id: \.idComercio) { comercioProductos in
                    
                    // 1. Título del Comercio
                    let comercio = Comercio(
                        idInterno: comercioProductos.idComercio,
                        nombre: comercioProductos.nombreComercio,
                        logoURL: comercioProductos.logoComercioURL
                    )
                    
                    TituloComercio(comercio: comercio)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            
                            // Items de Promociones
                            ForEach(comercioProductos.promociones) { promocion in
                                PromocionMiniatura(promocion: promocion) {
                                    Task {
                                        await homeViewModel.inicializarPromocionSeleccionada(
                                            idComercio: comercioProductos.idComercio,
                                            idPromocion: promocion.idInterno
                                        )
                                    }
                                }
                                .frame(height: 190)
                            }
                            
                            // Items de Productos
                            ForEach(comercioProductos.productos) { producto in
                                ProductoMiniatura(producto: producto) {
                                    Task {
                                        await homeViewModel.inicializarProductoSeleccionado(
                                            idComercio: comercioProductos.idComercio,
                                            idProducto: producto.idInterno
                                        )
                                    }
                                }
                                .frame(height: 190)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                    .background(.grisSurface)
                    .cornerRadius(12)
                    
                    Spacer().frame(height: 4)
                }
            }
            .padding(.horizontal, 16)
        }
        // --- Lógica de Bottom Sheets ---
        .sheet(item: $homeViewModel.promocionSeleccionada) { promocionSeleccionada in
            if (homeViewModel.comercio != nil){
                BottomSheetSeleccionPromocion(
                    promocion: promocionSeleccionada,
                    comercio: homeViewModel.comercio!,
                    onClose: {
                        homeViewModel.limpiarSeleccionado()
                    }
                )
                .onDisappear {
                    homeViewModel.limpiarSeleccionado()
                }
            }
        }
        .sheet(item: $homeViewModel.productoSeleccionado) { productoSeleccionado in
            if (homeViewModel.categoria != nil && homeViewModel.comercio != nil){
                BottomSheetSeleccionProducto(
                    producto: productoSeleccionado,
                    categoria: homeViewModel.categoria!,
                    comercio: homeViewModel.comercio!,
                    onClose: {
                        homeViewModel.limpiarSeleccionado()
                    }
                )
                .onDisappear {
                    homeViewModel.limpiarSeleccionado()
                }
            }
        }
    }
}

struct BottomSheetDirecciones: View {
    let onNuevaDireccion: () -> Void
    let onDireccionSeleccionada: () -> Void

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var direcciones: [UsuarioDireccion] {
        perfilUsuarioState.usuario?.direcciones ?? []
    }

    var body: some View {
        VStack(spacing: 8) {
            
            Text("Elegir dirección")
                .font(.custom("Barlow", size: 18))
                .bold()
            
            Button {
                onNuevaDireccion()
            } label: {
                HStack(spacing: 6) {
                    Image("icono_add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.negro)
                    
                    Text(
                        "Nueva dirección"
                    )
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(direcciones.enumerated()), id: \.offset) { _, direccion in
                        Button {
                            Task {
                                await perfilUsuarioState.actualizarDireccionSeleccionada(
                                    idDireccion: direccion.id
                                )
                                onDireccionSeleccionada()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image("icono_ubicacion")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.negro)
                                
                                Text(
                                    StringUtils.formatearDireccion(
                                        direccion.calle,
                                        direccion.numero,
                                        direccion.departamento)
                                )
                                .font(.custom("Barlow", size: 16))
                                .foregroundColor(.negro)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
            Spacer()
        }
        .padding()
        .background(Color.blanco)
    }
}

struct DireccionFueraDeCobertura: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
                .frame(height: 100)
            
            Image("icono_fuera_cobertura")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
            
            Text("Dirección inválida o fuera de nuestro rango de cobertura, por favor selecciona otra dirección.")
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BottomSheetNotificaciones: View {
    var onNotificacionClick: (String) -> Void
    
    @EnvironmentObject var notificacionesState: NotificacionesState
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 8)
            Titulo(titulo: "Notificaciones")
            Spacer().frame(height: 8)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    
                    // Notificaciones No Leídas
                    ForEach(notificacionesState.notificacionesNoLeidas) { notificacion in
                        NotificationRow(
                            notificacion: notificacion,
                            isLeida: false,
                            action: {
                                onNotificacionClick(notificacion.idPedido)
                            }
                        )
                    }
                    
                    // Notificaciones Leídas
                    ForEach(notificacionesState.notificacionesLeidas) { notificacion in
                        NotificationRow(
                            notificacion: notificacion,
                            isLeida: true,
                            action: {
                                onNotificacionClick(notificacion.idPedido)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.blanco)
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.hidden)
    }
}

// Componente para la fila (Row)
struct NotificationRow: View {
    let notificacion: Notificacion
    let isLeida: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                // Icono dinámico
                Image(isLeida ? "icono_mensaje_leido" : "icono_mensaje_noleido")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.negro)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(notificacion.titulo)
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                    
                    Text(notificacion.mensaje)
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(.negro)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(
                // Fondo sólido si no leída, borde si leída
                Group {
                    if isLeida {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.grisSurface, lineWidth: 1)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.grisSurface)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
