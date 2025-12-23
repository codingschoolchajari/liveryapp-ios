//
//  PerfilView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct PerfilView: View {

    @State private var mostrarBottomSheetDirecciones = false

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    //@EnvironmentObject var carritoViewModel: CarritoViewModel

    var body: some View {
        VStack(spacing: 24) {

            Spacer().frame(height: 24)

            Bienvenida()

            SeccionPerfil(mostrarBottomSheetDirecciones: $mostrarBottomSheetDirecciones)

            SeccionSesion()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.blanco)
        .sheet(isPresented: $mostrarBottomSheetDirecciones) {
            BottomSheetDireccionesView {
                mostrarBottomSheetDirecciones = false
            }
            .presentationDetents([.medium])
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

    var body: some View {
        VStack(spacing: 16) {

            TituloSeccion(text: "Perfil")

            FilaPerfil(icon: "icono_ubicacion", text: "Direcciones") {
                mostrarBottomSheetDirecciones = true
            }

            FilaPerfil(icon: "icono_favoritos", text: "Favoritos") {
                print("Navegar a favoritos")
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
    }
}
