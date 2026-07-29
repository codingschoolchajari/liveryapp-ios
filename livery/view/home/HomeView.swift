//
//  HomeView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct HomeView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var notificacionesState: NotificacionesState
    @StateObject var homeViewModel : HomeViewModel
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    private var sinDireccionSeleccionada: Bool {
        perfilUsuarioState.obtenerDireccionSeleccionada().isEmpty
    }

    private var numeroWhatsappSoporte: String {
        (perfilUsuarioState.configuracion?.numeroWhatsappSoporte ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.verdePrincipal
                    .frame(maxWidth: .infinity)
                    .frame(height: proxy.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                
                FranjaPrincipal(homeViewModel: homeViewModel)
                
                if  ( perfilUsuarioState.ciudadSeleccionada != nil
                      && perfilUsuarioState.ciudadSeleccionada == StringUtils.sinCobertura
                    ) || (
                        perfilUsuarioState.usuario != nil
                        && perfilUsuarioState.usuario!.direcciones?.isEmpty ?? true
                    ) || (
                        perfilUsuarioState.idDireccionSeleccionada == nil
                    )
                {
                    DireccionFueraDeCobertura()
                } else {
                    SelectorCategorias(homeViewModel: homeViewModel)
                    Spacer().frame(height: 8)

                    if homeViewModel.categoriaSeleccionada == "todos" {
                        ListaComercios(homeViewModel: homeViewModel)
                    } else {
                        FranjaBusqueda(homeViewModel: homeViewModel)
                        ListaComerciosProductos(homeViewModel: homeViewModel)
                    }
                }
                }
                .padding(.bottom, 16)

                if sinDireccionSeleccionada {
                    LottieView(
                        animationName: "touch",
                        endFrame: 85,
                        loopMode: .loop,
                        backgroundColor: .clear,
                        contentMode: .scaleAspectFit
                    )
                    .frame(width: 54, height: 122)
                    .offset(x: 72, y: -10)
                    .allowsHitTesting(false)
                }

                if !numeroWhatsappSoporte.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                abrirWhatsAppSoporte()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.verdePrincipal)

                                    Image("icono_whatsapp")
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                }
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                            .padding(.trailing, 20)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
        .background(Color.blanco)
        .onAppear {
            // Refrescar notificaciones cuando aparece la vista (similar a HomeLifecycleObserver en Android)
            if let email = perfilUsuarioState.usuario?.email {
                notificacionesState.refrescarNotificaciones(receptor: email)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refrescar notificaciones cuando la app vuelve del background (equivalente a onStart en Android)
            if let email = perfilUsuarioState.usuario?.email {
                notificacionesState.refrescarNotificaciones(receptor: email)
            }
        }
    }

    private func abrirWhatsAppSoporte() {
        let numero = numeroWhatsappSoporte.filter { $0.isNumber }
        guard !numero.isEmpty else { return }

        let mensaje = "Necesito ayuda con mi pedido\nEl email de mi usuario es : \(perfilUsuarioState.usuario?.email ?? "")"
        guard let url = URL(string: "https://wa.me/\(numero)?text=\(mensaje.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return
        }

        UIApplication.shared.open(url)
    }
}

struct FranjaPrincipal: View {

    @ObservedObject var homeViewModel: HomeViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var notificacionesState: NotificacionesState
    @EnvironmentObject var navManager: NavigationManager

    @State private var mostrarDirecciones = false
    @State private var mostrarNotificaciones = false
    @State private var mostrarLoginRequerido = false
    
    // Calcular notificaciones no leídas a partir del nuevo modelo
    private var notificacionesNoLeidas: [NotificacionUI] {
        let notificacionesUI = mapearNotificacionesParaUI(notificaciones: notificacionesState.notificaciones)
        return notificacionesUI.filter { $0.estado == ESTADO_NO_LEIDO }
    }

    var body: some View {
        HStack {
            Button {
                mostrarDirecciones = true
            } label: {
                HStack(spacing: 6) {
                    Text(
                        perfilUsuarioState.obtenerDireccionSeleccionada().isEmpty
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
                                if !notificacionesNoLeidas.isEmpty {
                                    Text("\(notificacionesNoLeidas.count)")
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
                    navManager.irAPremios()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("icono_premios")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blanco)
                            .overlay(alignment: .topTrailing) {
                                let giros = perfilUsuarioState.usuario?.premios?.girosRestantes
                                if let giros, giros > 0  {
                                    Text("\(giros)")
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
                    if !perfilUsuarioState.esInvitado {
                        navManager.select(.perfil)
                    } else {
                        mostrarLoginRequerido = true
                    }
                } label: {
                    Image("icono_perfil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blanco)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(.verdePrincipal)
        .clipShape(RoundedCorners(radius: 24, corners: [.bottomLeft, .bottomRight]))
        .sheet(isPresented: $mostrarLoginRequerido) {
            LoginRequiridoView {
                mostrarLoginRequerido = false
            }
            .presentationDetents([.fraction(0.75)])
        }
        .sheet(isPresented: $mostrarDirecciones) {
            BottomSheetDirecciones(
                homeViewModel: homeViewModel,
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
                    navManager.irAPedido(idPedido: idPedido)
                }
            )
            .onDisappear {
                // Marcar notificaciones como leídas cuando se cierra el sheet
                if let email = perfilUsuarioState.usuario?.email {
                    notificacionesState.marcarVisiblesComoLeidas(receptor: email)
                }
            }
        }
    }
}

struct FranjaBusqueda: View {
    @ObservedObject var homeViewModel: HomeViewModel
    
    var body: some View {
        Buscador(homeViewModel: homeViewModel)
            .padding(.bottom, 4)
            .zIndex(100)
    }
}

struct Buscador: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var estaExpandido = false
        
    var body: some View {
        let categoriaSeleccionada = homeViewModel.categoriaSeleccionada ?? "todos"
        let opcionTodos = "Todos los Productos"
        let subcategorias = perfilUsuarioState.configuracion?
            .categorias?
            .first(where: { $0.nombre.caseInsensitiveCompare(categoriaSeleccionada) == .orderedSame })?
            .subcategorias
            .map { $0.capitalized } ?? []
        let palabrasClave = [opcionTodos] + subcategorias

        let palabraSeleccionada = homeViewModel.palabraClaveSeleccionada
        let placeholder = (palabraSeleccionada?.isEmpty ?? true) ? opcionTodos : palabraSeleccionada!.capitalized

        ZStack {
            Text(placeholder)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(Color.grisSecundario)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 32)

            HStack {
                Spacer()
                Image(systemName: estaExpandido ? "chevron.up" : "chevron.down")
                    .foregroundColor(Color.grisSecundario)
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .padding(.trailing, 20)
            }
        }
        .frame(height: 24)
        .background(Color.blanco)
        .clipShape(RoundedCorners(
            radius: 32,
            corners: estaExpandido ? [.topLeft, .topRight] : .allCorners
        ))
        .overlay(
            RoundedCorners(radius: 32, corners: estaExpandido ? [.topLeft, .topRight] : .allCorners)
                .stroke(Color.negro, lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                estaExpandido.toggle()
            }
        }
        .overlay(alignment: .top) {
            if estaExpandido {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 34)
                    
                    VStack(spacing: 0) {
                        Divider().background(Color.grisSecundario)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(palabrasClave, id: \.self) { palabra in
                                    Button(action: {
                                        homeViewModel.onPalabraClaveSeleccionadaChange(
                                            palabra.caseInsensitiveCompare(opcionTodos) == .orderedSame ? nil : palabra
                                        )
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
                        .gesture(DragGesture(minimumDistance: 0))
                    }
                    .background(Color.blanco)
                    .clipShape(RoundedCorners(radius: 22, corners: [.bottomLeft, .bottomRight]))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 2)
        .zIndex(100)
    }
}

struct SelectorCategorias: View {

    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        let categoriaComercios = ListUtils.categorias.first { $0.idInterno == "todos" }
        let grupoComestiblesIDs: Set<String> = [
            "bebidas", "carnes", "empanadas", "ensaladas", "fritos", "hamburguesas", "helados",
            "milanesas", "panificados", "pastas", "picadas", "pizzas", "postres", "sandwiches", "sushi"
        ]
        let grupoFarmaciaIDs: Set<String> = ["farmacias"]
        let grupoKioskoIDs: Set<String> = ["alfajores", "chocolates", "galletitas", "golosinas", "snacks"]

        let grupoComestibles = ListUtils.categorias.filter { grupoComestiblesIDs.contains($0.idInterno) }
        let grupoFarmacias = ListUtils.categorias.filter { grupoFarmaciaIDs.contains($0.idInterno) }
        let grupoKiosko = ListUtils.categorias.filter { grupoKioskoIDs.contains($0.idInterno) }

        let gruposTematicos = [grupoComestibles, grupoFarmacias, grupoKiosko].filter { !$0.isEmpty }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 10) {
                if let categoriaComercios {
                    CategoriaGrupo(
                        categorias: [categoriaComercios],
                        categoriaSeleccionada: homeViewModel.categoriaSeleccionada,
                        onSeleccionar: homeViewModel.onCategoriaSeleccionadaChange
                    )
                }

                ForEach(Array(gruposTematicos.enumerated()), id: \.offset) { _, grupo in
                    CategoriaGrupo(
                        categorias: grupo,
                        categoriaSeleccionada: homeViewModel.categoriaSeleccionada,
                        onSeleccionar: homeViewModel.onCategoriaSeleccionadaChange
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
}

private struct CategoriaGrupo: View {
    let categorias: [Categoria]
    let categoriaSeleccionada: String?
    let onSeleccionar: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(categorias, id: \.idInterno) { categoria in
                CategoriaItem(
                    categoria: categoria,
                    seleccionada: categoriaSeleccionada == categoria.idInterno,
                    onClick: { onSeleccionar(categoria.idInterno) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.grisSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CategoriaItem: View {
    let categoria: Categoria
    let seleccionada: Bool
    let onClick: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Button(action: onClick) {
                Image(categoria.imagenGenerica ?? "")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 50)
                    .padding(2)
                    .frame(width: 80, height: 60)
                    .background(Color.grisSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(seleccionada ? Color.verdePrincipal : Color.clear, lineWidth: 3)
                    )
            }
            .buttonStyle(.plain)

            Text(categoria.nombre)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(.negro)
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

    private var estaAbierto: Bool {
        DateUtils.comercioEstaAbierto(horarios: comercio.horarios, estadoApertura: comercio.estadoApertura)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mitad Superior: Imagen
            ZStack(alignment: .topTrailing) {
                RemoteImage(url: URL(string: API.baseURL + "/" + comercio.imagenURL))
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .clipped()

                Text(estaAbierto ? "Abierto" : "Cerrado")
                    .font(.custom("Barlow", size: 11).bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(estaAbierto ? Color.verdePrincipal : Color.naranjaPrincipal)
                    .clipShape(Capsule())
                    .padding(8)
            }

            // Mitad Inferior:
            ComercioTitulo(comercio: comercio, mostrarEncabezado: true)
                .frame(height: 84)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .background(Color.grisSurface)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

struct ListaComerciosProductos: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        let comerciosProductos = homeViewModel.comerciosProductos
        
        ScrollView (showsIndicators: false){
            LazyVStack(spacing: 4) {
                ForEach(comerciosProductos, id: \.idComercio) { comercioProductos in
                    
                    // 1. Título del Comercio
                    let comercio = Comercio(
                        idInterno: comercioProductos.idComercio,
                        nombre: comercioProductos.nombreComercio,
                        estadoApertura: comercioProductos.estadoApertura,
                        horarios: comercioProductos.horarios,
                        logoURL: comercioProductos.logoComercioURL,
                        distanciaUsuario: comercioProductos.distanciaUsuario
                    )
                    
                    TituloComercio(
                        comercio: comercio,
                        mostrarBotonAdd: false,
                        mostrarEstadoApertura: true,
                        mostrarSubtituloDistancia: true,
                        altura: 60,
                        paddingHorizontal: 0
                    )
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        .onTapGesture {
                            navManager.homePath.append(NavigationManager.HomeDestination.comercio(idComercio: comercioProductos.idComercio))
                        }
                    
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
                                if producto.disponible && producto.esComplemento != true {
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
    @ObservedObject var homeViewModel: HomeViewModel
    let onNuevaDireccion: () -> Void
    let onDireccionSeleccionada: () -> Void

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @State private var mostrarLoginRequerido = false
    
    var direcciones: [UsuarioDireccion] {
        perfilUsuarioState.usuario?.direcciones ?? []
    }

    var body: some View {
        VStack(spacing: 8) {
            
            Text("Elegir dirección")
                .font(.custom("Barlow", size: 18))
                .bold()
            
            Button {
                if !perfilUsuarioState.esInvitado {
                    onNuevaDireccion()
                } else {
                    mostrarLoginRequerido = true
                }
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
                                homeViewModel.recalcularDistanciasComercios()
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
        .sheet(isPresented: $mostrarLoginRequerido) {
            LoginRequiridoView {
                mostrarLoginRequerido = false
            }
            .presentationDetents([.fraction(0.75)])
        }
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
            Titulo(titulo: "Notificaciones", textoColor: Color.verdePrincipal)
            Spacer().frame(height: 8)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    
                    // Notificaciones No Leídas
                    ForEach(notificacionesState.notificacionesNoLeidas) { notificacion in
                        NotificationRow(
                            notificacion: notificacion,
                            isLeida: false,
                            action: {
                                onNotificacionClick(notificacion.idReferencia)
                            }
                        )
                    }
                    
                    // Notificaciones Leídas
                    ForEach(notificacionesState.notificacionesLeidas) { notificacion in
                        NotificationRow(
                            notificacion: notificacion,
                            isLeida: true,
                            action: {
                                onNotificacionClick(notificacion.idReferencia)
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
    let notificacion: NotificacionUI
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
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
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
