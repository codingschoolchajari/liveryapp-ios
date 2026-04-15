//
//  PerfilView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct PerfilView: View {

    @State private var mostrarBottomSheetDirecciones = false
    @State private var mostrarAlertEliminarCuenta = false

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    //@EnvironmentObject var carritoViewModel: CarritoViewModel

    var body: some View {
        VStack(spacing: 24) {

            Spacer().frame(height: 24)

            Bienvenida()

            SeccionPerfil(mostrarBottomSheetDirecciones: $mostrarBottomSheetDirecciones)

            SeccionRepartos()

            SeccionSesion()

            Spacer()
            
            SeccionEliminarUsuario(mostrarAlertEliminarCuenta: $mostrarAlertEliminarCuenta)

            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.blanco)
        .sheet(isPresented: $mostrarBottomSheetDirecciones) {
            BottomSheetDireccionesView {
                mostrarBottomSheetDirecciones = false
            }
            .presentationDetents([.medium])
        }
        .alert(isPresented: $mostrarAlertEliminarCuenta) {
            Alert(
                title: Text("Confirmar Eliminación"),
                message: Text("¿Está seguro que desea eliminar su cuenta? Esta opción no se puede deshacer."),
                primaryButton: .destructive(Text("Sí")) {
                    Task {
                        await perfilUsuarioState.eliminarUsuario()
                    }
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
}

struct SeccionRepartos: View {
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        VStack(spacing: 16) {
            TituloSeccion(text: "Repartos")

            FilaPerfil(icon: "icono_pedidos", text: "Repartos") {
                navManager.perfilPath.append(NavigationManager.PerfilDestination.repartos)
            }
        }
    }
}

struct Bienvenida: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    var body: some View {
        VStack(spacing: 4) {

            Text("¡Hola, \(perfilUsuarioState.usuario?.datosPersonales?.nombre ?? "") \(perfilUsuarioState.usuario?.datosPersonales?.apellido ?? "")!")
                .font(.custom("Barlow", size: 16))
                .bold()
                .lineLimit(1)
                .foregroundColor(Color.negro)

            if let email = perfilUsuarioState.usuario?.email {
                Text(email)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(Color.grisSecundario)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SeccionPerfil: View {
    @Binding var mostrarBottomSheetDirecciones: Bool
    
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        VStack(spacing: 16) {

            TituloSeccion(text: "Perfil")

            FilaPerfil(icon: "icono_ubicacion", text: "Direcciones") {
                mostrarBottomSheetDirecciones = true
            }

            FilaPerfil(icon: "icono_favoritos", text: "Favoritos") {
                navManager.perfilPath.append(NavigationManager.PerfilDestination.favoritos)
            }
        }
    }
}

struct FilaPerfil: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.negro)
                
                Text(text)
                    .font(.custom("Barlow", size: 16))
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .foregroundColor(Color.negro)
    }
}

struct TituloSeccion: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("Barlow", size: 22))
            .bold()
            .foregroundColor(Color.negro)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

struct SeccionSesion: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 16) {

            TituloSeccion(text: "Sesión")
            
            Button {
                loginViewModel.signOut(
                    perfilUsuarioState: perfilUsuarioState
                )
            } label: {
                HStack(spacing: 12) {
                    Image("icono_logout")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.negro)
                    
                    Text("Cerrar Sesión")
                        .font(.custom("Barlow", size: 16))
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .foregroundColor(Color.negro)
        }
    }
}

struct BottomSheetDireccionesView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    //@EnvironmentObject var carritoViewModel: CarritoViewModel

    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Direcciones")
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .padding(.top, 8)

            let direcciones: [UsuarioDireccion] = perfilUsuarioState.usuario?.direcciones ?? []
            ForEach(direcciones, id: \.id) { direccion in
                HStack {
                    Image("icono_ubicacion")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.negro)
                    Text(
                        StringUtils.formatearDireccion(
                            direccion.calle,
                            direccion.numero,
                            direccion.departamento
                        )
                    )
                    .font(.custom("Barlow", size: 16))
                    .foregroundColor(.negro)
                    
                    Spacer()
                    Button {
                        Task {
                            await perfilUsuarioState.eliminarDireccion(
                                idDireccion: direccion.id
                            )
                            //await carritoViewModel.calcularCostoEnvio(
                            //    direccion:
                            //)
                        }
                    } label: {
                        Image("icono_delete")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.rojoError)
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
    }
}

struct SeccionEliminarUsuario: View {
    @Binding var mostrarAlertEliminarCuenta: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                mostrarAlertEliminarCuenta = true
            } label: {
                Text("Eliminar Usuario")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(.blanco)
                    .background(Color.rojoError)
                    .cornerRadius(24)
            }
            .padding(.horizontal, 64)
        }
    }
}
