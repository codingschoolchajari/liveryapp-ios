//
//  MisPuntosView.swift
//  livery
//
import SwiftUI

struct MisPuntosView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @StateObject var misPuntosViewModel: MisPuntosViewModel

    init(perfilUsuarioState: PerfilUsuarioState) {
        _misPuntosViewModel = StateObject(
            wrappedValue: MisPuntosViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }

    private var pestaniaSeleccionada: Binding<String> {
        Binding(
            get: { misPuntosViewModel.pestaniaActiva },
            set: { misPuntosViewModel.pestaniaActiva = $0 }
        )
    }
    private let opciones = ["Historial", "Productos", "Canjeados"]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.verdeSistemaPuntos
                    .frame(maxWidth: .infinity)
                    .frame(height: proxy.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    Color.verdeSistemaPuntos
                        .frame(height: 70)
                        .clipShape(RoundedCorners(radius: 24, corners: [.bottomLeft, .bottomRight]))
                        .overlay(alignment: .center) {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.blanco)
                                .frame(width: UIScreen.main.bounds.width - 32, height: 44)
                                .overlay(alignment: .leading) {
                                    Text("Mis Puntos Livery")
                                        .font(.custom("Barlow", size: 14))
                                        .bold()
                                        .foregroundColor(.verdeSistemaPuntos)
                                        .padding(.leading, 16)
                                }
                                .overlay(alignment: .trailing) {
                                    Text("\(DoubleUtils.formatearPuntos(valor: misPuntosViewModel.puntos ?? 0)) pts")
                                        .font(.custom("Barlow", size: 14))
                                        .bold()
                                        .foregroundColor(.verdeSistemaPuntos)
                                        .padding(.trailing, 16)
                                }
                        }

                    Spacer().frame(height: 4)

                    HStack(spacing: 0) {
                        ForEach(Array(opciones.enumerated()), id: \.element) { index, opcion in
                            let seleccionada = pestaniaSeleccionada.wrappedValue == opcion
                            Button(action: { pestaniaSeleccionada.wrappedValue = opcion }) {
                                Text(opcion)
                                    .font(.custom("Barlow", size: 12))
                                    .bold()
                                    .foregroundColor(seleccionada ? .blanco : .grisSecundario)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(seleccionada ? Color.verdeSistemaPuntos : Color.grisSurface)
                            }
                            .overlay(
                                Rectangle()
                                    .stroke(seleccionada ? Color.verdeSistemaPuntos : Color.grisSecundario, lineWidth: 1)
                            )
                            .clipShape(
                                RoundedCorners(
                                    radius: index == 0 || index == opciones.count - 1 ? 14 : 0,
                                    corners: index == 0 ? [.topLeft, .bottomLeft]
                                        : index == opciones.count - 1 ? [.topRight, .bottomRight]
                                        : []
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 50)

                    Spacer().frame(height: 16)

                    switch pestaniaSeleccionada.wrappedValue {
                    case "Historial":
                        HistorialPuntos(misPuntosViewModel: misPuntosViewModel)
                    case "Productos":
                        ProductosPuntos(misPuntosViewModel: misPuntosViewModel)
                    case "Canjeados":
                        CanjeadosPuntos(misPuntosViewModel: misPuntosViewModel)
                    default:
                        EmptyView()
                    }

                    Spacer()
                }
            }
        }
        .background(Color.blanco)
        .onAppear {
            if let email = perfilUsuarioState.usuario?.email {
                misPuntosViewModel.cargarPuntos(email: email)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// MARK: - HistorialPuntos

private struct HistorialPuntos: View {
    @ObservedObject var misPuntosViewModel: MisPuntosViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    var body: some View {
        let sistemaDePuntos = perfilUsuarioState.configuracion?.sistemaDePuntos?
            .filter { $0.mostrarEnListaPuntos } ?? []

        VStack(spacing: 0) {
            if !sistemaDePuntos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(sistemaDePuntos, id: \.concepto) { item in
                            TarjetaPuntos(item: item)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 88)

                Spacer().frame(height: 24)
            }

            Rectangle()
                .fill(Color.grisSecundario)
                .frame(height: 1)

            Spacer().frame(height: 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(misPuntosViewModel.historialPuntos.enumerated()), id: \.element.id) { index, item in
                        FilaHistorial(item: item)
                        if index < misPuntosViewModel.historialPuntos.count - 1 {
                            Spacer().frame(height: 8)
                            Rectangle()
                                .fill(Color.grisSecundario)
                                .frame(height: 1)
                                .padding(.leading, 62)
                            Spacer().frame(height: 8)
                        }
                    }

                    if misPuntosViewModel.hayMasHistorial {
                        ProgressView()
                            .padding()
                            .onAppear {
                                if let email = perfilUsuarioState.usuario?.email {
                                    misPuntosViewModel.cargarHistorial(email: email)
                                }
                            }
                    }

                    Spacer().frame(height: 80)
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            if let email = perfilUsuarioState.usuario?.email {
                misPuntosViewModel.resetHistorial()
                misPuntosViewModel.cargarHistorial(email: email)
            }
        }
    }
}

// MARK: - FilaHistorial

private struct FilaHistorial: View {
    let item: HistorialPuntosItem

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: URL(string: API.baseURL + "/" + item.logoURL))
                .frame(width: 50, height: 50)
                .background(Color.grisSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.titulo)
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.negro)
                if !item.fechaCreacion.isEmpty {
                    Text(DateUtils.fechaATexto(fechaStr: item.fechaCreacion))
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(.grisTerciario)
                }
            }

            Spacer()

            Text(item.puntos >= 0
                 ? "+ \(DoubleUtils.formatearPuntos(valor: item.puntos)) pts"
                 : "- \(DoubleUtils.formatearPuntos(valor: -item.puntos)) pts")
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(item.puntos >= 0 ? .verdeSistemaPuntos : .red)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TarjetaPuntos

private struct TarjetaPuntos: View {
    let item: ConfiguracionSistemaPuntos

    var body: some View {
        HStack(spacing: 0) {
            RemoteImage(url: URL(string: API.baseURL + "/" + item.imagenURL))
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text(" \(DoubleUtils.formatearPuntos(valor: item.puntos)) pts ")
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(.blanco)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.verdeSistemaPuntos)
                .clipShape(Capsule())

                Text(item.titulo)
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.negro)

                Text(item.descripcion)
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.grisTerciario)
            }
            .padding(12)
        }
        .frame(width: 280, height: 80)
        .background(Color.blanco)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - ProductosPuntos

private struct ProductosPuntos: View {
    @ObservedObject var misPuntosViewModel: MisPuntosViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @State private var filtroSeleccionado = "Todos"
    @State private var mensajeToast: String? = nil

    private let filtros = ["Todos", "Comidas", "Helados", "Envíos"]

    var body: some View {
        let premios = misPuntosViewModel.premiosCanjeables
        let premiosFiltrados: [PremioCanjeable] = {
            switch filtroSeleccionado {
            case "Todos": return premios
            case "Envíos": return premios.filter { $0.categoria.lowercased() == "envios_gratis" }
            default: return premios.filter { $0.categoria.lowercased() == filtroSeleccionado.lowercased() }
            }
        }()

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(filtros, id: \.self) { filtro in
                    FiltroChip(
                        texto: filtro,
                        seleccionado: filtroSeleccionado == filtro,
                        onClick: { filtroSeleccionado = filtro }
                    )
                }
            }
            .padding(.horizontal, 12)

            Spacer().frame(height: 12)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(premiosFiltrados, id: \.id) { premio in
                        FilaProductoCanjeable(
                            item: premio,
                            puntosUsuario: misPuntosViewModel.puntos ?? 0,
                            onCanjear: { idProducto, idComercio, onComplete in
                                misPuntosViewModel.canjearProducto(
                                    idProducto: idProducto,
                                    idComercio: idComercio,
                                    email: perfilUsuarioState.usuario?.email ?? ""
                                ) { exito in
                                    if exito {
                                        misPuntosViewModel.cargarPremiosCanjeados(email: perfilUsuarioState.usuario?.email ?? "")
                                        misPuntosViewModel.pestaniaActiva = "Canjeados"
                                    } else {
                                        mensajeToast = "Error al canjear el producto"
                                    }
                                    onComplete()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            misPuntosViewModel.cargarPremiosCanjeables()
        }
        .overlay(alignment: .bottom) {
            if let toast = mensajeToast {
                Text(toast)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.blanco)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.bottom, 20)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            mensajeToast = nil
                        }
                    }
            }
        }
    }
}

// MARK: - FilaProductoCanjeable

private struct FilaProductoCanjeable: View {
    let item: PremioCanjeable
    let puntosUsuario: Int
    let onCanjear: (_ idProducto: String, _ idComercio: String, _ onComplete: @escaping () -> Void) -> Void

    @State private var flashState: Bool? = nil
    @State private var canjeando = false
    @State private var flipped = false

    var body: some View {
        let puedeCanjear = puntosUsuario >= item.puntos

        ZStack {
            RowFront(item: item)
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            if flashState != nil {
                RowBack(
                    item: item,
                    puedeCanjear: puedeCanjear,
                    canjeando: canjeando,
                    onCanjear: {
                        canjeando = true
                        onCanjear(item.idProducto, item.idComercio) {
                            canjeando = false
                        }
                    }
                )
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.blanco)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .onTapGesture {
            if flashState == nil {
                withAnimation(.easeInOut(duration: 0.5)) {
                    flashState = puedeCanjear
                    flipped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + (puedeCanjear ? 5 : 3)) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        flipped = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        flashState = nil
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: flipped)
    }
}

private struct RowFront: View {
    let item: PremioCanjeable

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: URL(string: API.baseURL + "/" + (item.logoComercioURL ?? "")))
                .frame(width: 62.5, height: 62.5)
                .background(Color.grisSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nombreProducto ?? "")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                Text("\(DoubleUtils.formatearPuntos(valor: item.puntos)) pts")
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.verdeSistemaPuntos)
            }

            Spacer()

            RemoteImage(url: URL(string: API.baseURL + "/" + (item.imagenURL ?? "")))
                .frame(width: 62.5, height: 62.5)
                .background(Color.grisSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .clipped()
        }
        .padding(12)
    }
}

private struct RowBack: View {
    let item: PremioCanjeable
    let puedeCanjear: Bool
    let canjeando: Bool
    let onCanjear: () -> Void

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                if canjeando {
                    ProgressView()
                        .tint(.blanco)
                } else if puedeCanjear {
                    Text("Canjear Premio")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.blanco)
                } else {
                    Text("No Tenés Puntos Suficientes")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.blanco)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
        }
        .padding(12)
        .frame(height: 86.5)
        .background(puedeCanjear ? Color.verdeSistemaPuntos : Color.grisSecundario)
        .cornerRadius(16)
        .onTapGesture {
            if puedeCanjear && !canjeando {
                onCanjear()
            }
        }
    }
}

// MARK: - CanjeadosPuntos

private struct CanjeadosPuntos: View {
    @ObservedObject var misPuntosViewModel: MisPuntosViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @State private var mostrarDialogoError = false

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(misPuntosViewModel.premiosCanjeados, id: \.id) { premio in
                        FilaPremioCanjeado(item: premio) {
                            if carritoViewModel.existePremioEnCarrito(idInterno: premio.idInterno) {
                                mostrarDialogoError = true
                            } else if premio.estado != "UTILIZADO" {
                                misPuntosViewModel.seleccionarCanjeado(premioCanjeado: premio)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            if let email = perfilUsuarioState.usuario?.email {
                misPuntosViewModel.cargarPremiosCanjeados(email: email)
            }
        }
        .sheet(item: $misPuntosViewModel.canjeadoSeleccionado) { canjeado in
            SeleccionProductoCanjeadoView(
                misPuntosViewModel: misPuntosViewModel,
                canjeado: canjeado
            )
        }
        .alert("Premio Canjeado", isPresented: $mostrarDialogoError) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("Este premio ya fue agregado al carrito.")
        }
    }
}

// MARK: - FilaPremioCanjeado

private struct FilaPremioCanjeado: View {
    let item: PremioCanjeado
    let onClick: () -> Void

    private var esSinUtilizar: Bool { item.estado != "UTILIZADO" }

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: URL(string: API.baseURL + "/" + (item.logoComercioURL ?? "")))
                .frame(width: 62.5, height: 62.5)
                .background(Color.grisSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nombreProducto ?? "")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)

                Text(DateUtils.fechaATexto(fechaStr: item.fechaCanje))
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.grisTerciario)

                Text(item.estado == "UTILIZADO" ? "Utilizado" : "Sin Utilizar")
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(item.estado == "UTILIZADO" ? .verdeSistemaPuntos : .naranjaPrincipal)
            }

            Spacer()

            RemoteImage(url: URL(string: API.baseURL + "/" + (item.imagenURL ?? "")))
                .frame(width: 62.5, height: 62.5)
                .background(Color.grisSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .clipped()
        }
        .padding(12)
        .background(Color.blanco)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .onTapGesture {
            if esSinUtilizar {
                onClick()
            }
        }
    }
}

// MARK: - SeleccionProductoCanjeadoView

private struct SeleccionProductoCanjeadoView: View {
    @ObservedObject var misPuntosViewModel: MisPuntosViewModel
    let canjeado: PremioCanjeado

    var body: some View {
        VStack {
            if let producto = misPuntosViewModel.productoSeleccionado,
               let categoria = misPuntosViewModel.categoria,
               let comercio = misPuntosViewModel.comercio {

                BottomSheetSeleccionProducto(
                    producto: producto,
                    categoria: categoria,
                    comercio: comercio,
                    onClose: {
                        misPuntosViewModel.limpiarCanjeadoSeleccionado()
                        misPuntosViewModel.limpiarProductoSeleccionado()
                    }
                )
            }
        }
        .onAppear {
            Task {
                await misPuntosViewModel.inicializarProductoCanjeado(
                    idComercio: canjeado.idComercio,
                    idProducto: canjeado.idProducto,
                    idPremio: canjeado.idInterno
                )
            }
        }
    }
}

// MARK: - FiltroChip

private struct FiltroChip: View {
    let texto: String
    let seleccionado: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Text(texto)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(seleccionado ? .blanco : .grisSecundario)
                .padding(.horizontal, 4)
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .background(seleccionado ? Color.verdeSistemaPuntos : Color.blanco)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(seleccionado ? Color.verdeSistemaPuntos : Color.grisSecundario, lineWidth: 1)
                )
        }
    }
}