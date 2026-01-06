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
                contenidoPrincipal
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
    
    private var contenidoPrincipal: some View {
        VStack {
            ZStack {
                if direccionViewModel.coordenadas != nil {
                    GoogleMapView(coordenadas: $direccionViewModel.coordenadas)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.verdePrincipal, lineWidth: 2)
                        )

                    Image("icono_ubicacion_mapa")
                        .resizable()
                        .frame(width: 60, height: 60)
                } else {
                    ProgressView()
                }
            }
            .padding(8)
            .frame(maxHeight: 350)

            FormularioDireccionView(direccionViewModel: direccionViewModel)
            Spacer()
        }
    }
}

struct FormularioDireccionView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var navManager: NavigationManager
    
    @ObservedObject var direccionViewModel: DireccionViewModel

    var body: some View {
        VStack(spacing: 8) {
            TextField(
                text: $direccionViewModel.calle,
                prompt: Text("Calle")
                    .foregroundColor(.grisSecundario)
                    .font(.custom("Barlow", size: 16))
            ) {
                Text("Calle")
            }
            .tint(.verdePrincipal)
            .autocapitalization(.words)
            .disableAutocorrection(true)
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            .background(Color.blanco)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            
            TextField(
                text: $direccionViewModel.numero,
                prompt: Text("Número")
                    .foregroundColor(.grisSecundario)
                    .font(.custom("Barlow", size: 16))
            ) {
                Text("Número")
            }
            .tint(.verdePrincipal)
            .autocapitalization(.words)
            .disableAutocorrection(true)
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            .background(Color.blanco)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            
            TextField(
                text: $direccionViewModel.departamento,
                prompt: Text("Departamento")
                    .foregroundColor(.grisSecundario)
                    .font(.custom("Barlow", size: 16))
            ) {
                Text("Departamento")
            }
            .tint(.verdePrincipal)
            .autocapitalization(.words)
            .disableAutocorrection(true)
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            .background(Color.blanco)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            
            Text("Indicaciones de Entrega")
                .foregroundColor(.grisSecundario)
                .font(.custom("Barlow", size: 16))
                .bold()
                .padding(.top, 4)
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $direccionViewModel.indicaciones)
                .scrollContentBackground(.hidden)
                .background(Color.blanco)
                .tint(.verdePrincipal)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .frame(minHeight: 70, maxHeight: 70) // ≈ 3 líneas
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
                .onChange(of: direccionViewModel.indicaciones) { oldValue, newValue in
                    if newValue.count > 100 {
                        direccionViewModel.indicaciones = String(newValue.prefix(100))
                    }
                }
        }
        .padding(.horizontal, 16)
        
        HStack {
            Spacer()
            Button {
                guardarDireccion(
                    navManager: navManager,
                    perfilUsuarioState: perfilUsuarioState,
                    direccionViewModel: direccionViewModel
                )
            } label : {
                Text("Guardar Dirección")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .frame(width: 250, height: 40)
                    .foregroundColor(.blanco)
                    .background(esFormularioValido(direccionViewModel) ?
                        .verdePrincipal : .grisSecundario)
                    .cornerRadius(16)
            }
            .disabled(!esFormularioValido(direccionViewModel))
            Spacer()
        }
    }
    
    private func esFormularioValido(
        _ direccionViewModel: DireccionViewModel
    ) -> Bool {
        
        if(direccionViewModel.calle.isEmpty
           || direccionViewModel.numero.isEmpty
           || direccionViewModel.coordenadas == nil
        ) {
            return false
        } else {
            return true
        }
    }
    
    private func guardarDireccion(
        navManager: NavigationManager,
        perfilUsuarioState: PerfilUsuarioState,
        direccionViewModel: DireccionViewModel
    ) {
        if let email = perfilUsuarioState.usuario?.email {
            Task {
                let idDireccion = UUID().uuidString.lowercased()
                
                let direccionGuardada = await direccionViewModel.guardarDireccion(
                    perfilUsuarioState: perfilUsuarioState,
                    email: email,
                    idDireccion: idDireccion
                )
                if (direccionGuardada) {
                    await perfilUsuarioState.actualizarDireccionSeleccionada(idDireccion: idDireccion)
                }
                await perfilUsuarioState.buscarUsuario()
                navManager.select(.home)
            }
        }
    }
}
