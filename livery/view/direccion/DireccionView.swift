//
//  DireccionView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI
import GoogleMaps

struct DireccionView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject private var direccionViewModel = DireccionViewModel()

    var body: some View {
        VStack {
            switch direccionViewModel.permissionState {

            case .checking:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .denied:
                LocationPermissionView()

            case .restricted:
                VStack(spacing: 12) {
                    Text("Ubicación restringida")
                        .font(.custom("Barlow", size: 16))
                        .bold()
                        .foregroundColor(.negro)

                    Text("El acceso a la ubicación está restringido por el sistema.")
                        .font(.custom("Barlow", size: 16))
                        .bold()
                        .foregroundColor(.negro)
                        .multilineTextAlignment(.center)
                }
                .padding()

            case .granted:
                FormularioDireccionView(direccionViewModel: direccionViewModel)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .background(Color.blanco)
        .task {
            direccionViewModel.verificarPermisoUbicacion()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )
        ) { _ in
            direccionViewModel.verificarPermisoUbicacion()
        }
    }
}

struct FormularioDireccionView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var navManager: NavigationManager
    
    @ObservedObject var direccionViewModel: DireccionViewModel
    
    @FocusState private var campoEnFoco: Campos?

    private var camposDireccionHabilitados: Bool {
        direccionViewModel.coordenadas != nil
    }

    enum Campos {
        case calle, numero, departamento, indicaciones
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {

                    MapaView(direccionViewModel: direccionViewModel)

                    // Toggle: Buscar Dirección / Cargar Manualmente
                    HStack(spacing: 0) {
                        Button {
                            direccionViewModel.seleccionarModo(manual: false)
                        } label: {
                            Text("Buscar Dirección")
                                .font(.custom("Barlow", size: 11))
                                .bold()
                                .foregroundColor(!direccionViewModel.modoManual ? Color.blanco : Color.grisSecundario)
                                .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30)
                                .background(!direccionViewModel.modoManual ? Color.verdePrincipal : Color.blanco)
                        }
                        Button {
                            direccionViewModel.seleccionarModo(manual: true)
                        } label: {
                            Text("Cargar Manualmente")
                                .font(.custom("Barlow", size: 11))
                                .bold()
                                .foregroundColor(direccionViewModel.modoManual ? Color.blanco : Color.grisSecundario)
                                .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30)
                                .background(direccionViewModel.modoManual ? Color.verdePrincipal : Color.blanco)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.grisSecundario, lineWidth: 1))
                    .padding(.horizontal, 30)

                    // Buscador (solo en modo Buscar Dirección)
                    PlacesSearchBar(coordenadasInicialesGPS: direccionViewModel.coordenadasInicialesGPS) { place in
                        direccionViewModel.actualizarDesdePlace(place)
                    }
                    .opacity(direccionViewModel.modoManual ? 0 : 1)
                    .allowsHitTesting(!direccionViewModel.modoManual)

                    // Calle | Número | Dpto (proporciones 2:1:1)
                    GeometryReader { geo in
                        let unit = (geo.size.width - 16) / 4.0
                        HStack(alignment: .top, spacing: 8) {

                            // Calle
                            let calleHabilitado = direccionViewModel.modoManual ? camposDireccionHabilitados : false
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calle")
                                    .font(.custom("Barlow", size: 12))
                                    .bold()
                                    .foregroundColor(.negro)
                                TextField(
                                    text: Binding(
                                        get: { direccionViewModel.calle },
                                        set: { direccionViewModel.onCalleChange($0) }
                                    ),
                                    prompt: Text("").foregroundColor(.grisSecundario)
                                ) {}
                                .focused($campoEnFoco, equals: .calle)
                                .id(Campos.calle)
                                .tint(.verdePrincipal)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(.negro)
                                .padding(12)
                                .background(calleHabilitado ? Color.blanco : Color.grisSurface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grisSecundario, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .disabled(!calleHabilitado)
                            }
                            .frame(width: unit * 2)

                            // Número
                            let numHabilitado = direccionViewModel.modoManual ? camposDireccionHabilitados : !direccionViewModel.calle.isEmpty
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Número")
                                    .font(.custom("Barlow", size: 12))
                                    .bold()
                                    .foregroundColor(.negro)
                                TextField(
                                    text: Binding(
                                        get: { direccionViewModel.numero },
                                        set: { direccionViewModel.onNumeroChange($0) }
                                    ),
                                    prompt: Text("").foregroundColor(.grisSecundario)
                                ) {}
                                .focused($campoEnFoco, equals: .numero)
                                .id(Campos.numero)
                                .tint(.verdePrincipal)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(.negro)
                                .padding(12)
                                .background(numHabilitado ? Color.blanco : Color.grisSurface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grisSecundario, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .disabled(!numHabilitado)
                            }
                            .frame(width: unit)

                            // Dpto
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dpto (edificios)")
                                    .font(.custom("Barlow", size: 12))
                                    .bold()
                                    .foregroundColor(.negro)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                TextField(
                                    text: $direccionViewModel.departamento,
                                    prompt: Text("").foregroundColor(.grisSecundario)
                                ) {}
                                .focused($campoEnFoco, equals: .departamento)
                                .id(Campos.departamento)
                                .tint(.verdePrincipal)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(.negro)
                                .padding(12)
                                .background(Color.blanco)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.grisSecundario, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(width: unit)
                        }
                    }
                    .frame(height: 72)

                    // Indicaciones
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Indicaciones de Entrega")
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(.negro)
                        TextEditor(text: $direccionViewModel.indicaciones)
                            .focused($campoEnFoco, equals: .indicaciones)
                            .id(Campos.indicaciones)
                            .scrollContentBackground(.hidden)
                            .background(Color.blanco)
                            .tint(.verdePrincipal)
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(.negro)
                            .frame(minHeight: 35, maxHeight: 35)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.grisSecundario, lineWidth: 1)
                            )
                            .onChange(of: direccionViewModel.indicaciones) { _, newValue in
                                if newValue.count > 200 {
                                    direccionViewModel.indicaciones = String(newValue.prefix(200))
                                }
                            }
                    }

                    // Celular
                    CelularFieldDireccion(
                        pais: direccionViewModel.celularPais,
                        numero: direccionViewModel.celularNumero,
                        onPaisChange: { direccionViewModel.onCelularPaisChange($0) },
                        onNumeroChange: { direccionViewModel.onCelularNumeroChange($0) }
                    )

                    Text("Te contactaremos solo en caso de ser necesario.")
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(.grisSecundario)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)

                    HStack {
                        Spacer()
                        Button {
                            guardarDireccion(
                                navManager: navManager,
                                perfilUsuarioState: perfilUsuarioState,
                                direccionViewModel: direccionViewModel
                            )
                        } label: {
                            Text("Guardar Dirección")
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .frame(width: 250, height: 40)
                                .foregroundColor(.blanco)
                                .background(esFormularioValido(direccionViewModel) ? Color.verdePrincipal : Color.grisSecundario)
                                .cornerRadius(16)
                        }
                        .disabled(!esFormularioValido(direccionViewModel))
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: campoEnFoco) { _, nuevoCampo in
                if let campo = nuevoCampo {
                    withAnimation {
                        proxy.scrollTo(campo, anchor: .center)
                    }
                }
            }
            .alert("Advertencia", isPresented: $direccionViewModel.mostrarPopupAdvertencia) {
                Button("Cancelar", role: .cancel) {
                    direccionViewModel.ocultarPopupAdvertencia()
                }
                Button("Guardar Igualmente") {
                    guardarDireccionConfirmada(
                        navManager: navManager,
                        perfilUsuarioState: perfilUsuarioState,
                        direccionViewModel: direccionViewModel
                    )
                }
            } message: {
                Text("La calle y número indicados no coinciden con la posición marcada en el mapa.\n\nAconsejamos utilizar el buscador que se encuentra en la parte superior del mapa.")
            }
            .alert("Importante", isPresented: $direccionViewModel.mostrarAdvertencia) {
                Button("Entendido") {
                    direccionViewModel.mostrarAdvertencia = false
                }
            } message: {
                Text("La Ubicación en el Mapa debe coincidir con la Dirección Cargada.\n\nMover el Pin en el mapa para ajustarlo.")
            }
        }
    }
    
    private struct MapaView: View {
        @ObservedObject var direccionViewModel: DireccionViewModel
        
        var body: some View {
            ZStack {
                // 🗺️ MAPA (fondo)
                if direccionViewModel.coordenadas != nil {
                    GoogleMapView(coordenadas: $direccionViewModel.coordenadas)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.verdePrincipal, lineWidth: 2)
                        )
                }
                // 📍 PIN CENTRADO
                Image("icono_ubicacion_mapa")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .zIndex(1)
            }
            .padding(8)
            .frame(height: 300)
        }
    }
    
    private func esFormularioValido(
        _ direccionViewModel: DireccionViewModel
    ) -> Bool {
        !direccionViewModel.calle.isEmpty
            && !direccionViewModel.numero.isEmpty
            && !direccionViewModel.celularNumero.isEmpty
            && direccionViewModel.coordenadas != nil
    }
    
    private func guardarDireccion(
        navManager: NavigationManager,
        perfilUsuarioState: PerfilUsuarioState,
        direccionViewModel: DireccionViewModel
    ) {
        Task {
            if let idDireccion = await direccionViewModel.guardarDireccion(
                perfilUsuarioState: perfilUsuarioState
            ) {
                await perfilUsuarioState.actualizarDireccionSeleccionada(idDireccion: idDireccion)
                await perfilUsuarioState.buscarUsuario()
                navManager.select(.home)
            }
        }
    }

    private func guardarDireccionConfirmada(
        navManager: NavigationManager,
        perfilUsuarioState: PerfilUsuarioState,
        direccionViewModel: DireccionViewModel
    ) {
        Task {
            if let idDireccion = await direccionViewModel.confirmarGuardar(
                perfilUsuarioState: perfilUsuarioState
            ) {
                await perfilUsuarioState.actualizarDireccionSeleccionada(idDireccion: idDireccion)
                await perfilUsuarioState.buscarUsuario()
                navManager.select(.home)
            }
        }
    }

    private struct CelularFieldDireccion: View {
        let pais: String
        let numero: String
        let onPaisChange: (String) -> Void
        let onNumeroChange: (String) -> Void

        private struct PaisCelular: Identifiable {
            let id = UUID()
            let iso: String
            let codigo: String
        }

        private let paises: [PaisCelular] = [
            PaisCelular(iso: "AR", codigo: "+54"),
            PaisCelular(iso: "BR", codigo: "+55"),
            PaisCelular(iso: "CL", codigo: "+56"),
            PaisCelular(iso: "UY", codigo: "+598"),
            PaisCelular(iso: "PY", codigo: "+595")
        ]

        var body: some View {
            let paisActual = paises.first { $0.codigo == pais } ?? paises[0]
            HStack(spacing: 8) {
                Menu {
                    ForEach(paises) { p in
                        Button {
                            onPaisChange(p.codigo)
                        } label: {
                            HStack(spacing: 8) {
                                AsyncImage(url: URL(string: "https://flagcdn.com/80x60/\(p.iso.lowercased()).png")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 20, height: 15)
                                            .clipShape(RoundedRectangle(cornerRadius: 2))
                                    } else {
                                        Color.grisSurface
                                            .frame(width: 20, height: 15)
                                            .clipShape(RoundedRectangle(cornerRadius: 2))
                                    }
                                }
                                Text("\(p.iso) \(p.codigo)")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        AsyncImage(url: URL(string: "https://flagcdn.com/80x60/\(paisActual.iso.lowercased()).png")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 15)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            } else {
                                Color.grisSurface
                                    .frame(width: 20, height: 15)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            }
                        }
                        Text(paisActual.codigo)
                            .font(.custom("Barlow", size: 13))
                            .bold()
                            .foregroundColor(.negro)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.grisSecundario)
                    }
                    .frame(width: 80, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )
                }

                TextField(
                    text: Binding(
                        get: { numero },
                        set: { onNumeroChange($0) }
                    ),
                    prompt: Text("Número de Celular")
                        .foregroundColor(.grisSecundario)
                        .font(.custom("Barlow", size: 16))
                ) {}
                .keyboardType(.numberPad)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .tint(.verdePrincipal)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.blanco)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

