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
    //@EnvironmentObject var carritoViewModel: CarritoViewModel

    @StateObject var direccionViewModel = DireccionViewModel()
    //@Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Spacer().frame(height: 8)

            ZStack {
                if direccionViewModel.coordenadas != nil {
                    GoogleMapView(coordenadas: $direccionViewModel.coordenadas)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )

                    Image("icono_ubicacion_mapa")
                        .resizable()
                        .frame(width: 60, height: 60)
                } else {
                    ProgressView()
                }
            }
            .padding(4)
            .frame(maxHeight: .infinity)

            VStack(spacing: 8) {

                HStack(spacing: 8) {
                    TextField("Calle", text: $direccionViewModel.calle)
                        .frame(maxWidth: .infinity)

                    TextField("Número", text: $direccionViewModel.numero)
                        .frame(width: 90)
                }

                TextField("Departamento", text: $direccionViewModel.departamento)

                TextEditor(text: $direccionViewModel.indicaciones)
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray))

                let enabled = !direccionViewModel.calle.isEmpty && !direccionViewModel.numero.isEmpty

                Button {
                    Task {
                        guard let usuario = perfilUsuarioState.usuario else { return }

                        let id = UUID().uuidString
                        //await direccionViewModel.guardarDireccion(usuario.email, id)
                        await perfilUsuarioState.actualizarDireccionSeleccionada(idDireccion: id)
                        await perfilUsuarioState.buscarUsuario()
                        /*
                        carritoViewModel.calcularCostoEnvio(
                            perfilUsuarioState.obtenerUsuarioDireccion()
                        )
                        dismiss()
                         */
                    }
                } label: {
                    Text("Guardar Dirección")
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 35)
                        .background(enabled ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(enabled ? .white : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .disabled(!enabled)
                .padding(.horizontal, 60)
            }
            .padding()
        }
        .task {
            direccionViewModel.verificarPermisoUbicacion()
        }
    }
}
