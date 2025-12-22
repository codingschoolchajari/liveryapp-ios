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
        .task {
            direccionViewModel.verificarPermisoUbicacion()
        }
    }
}

struct FormularioDireccionView: View {
    
    @ObservedObject var direccionViewModel: DireccionViewModel
    
    @State private var calle: String = ""
    @State private var numero: String = ""
    @State private var departamento: String = ""
    @State private var indicaciones: String = ""

    var body: some View {
        VStack(spacing: 8) {
            TextField("Calle", text: $calle)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
                .background(Color.blanco)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
            
            TextField("Número", text: $numero)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
                .background(Color.blanco)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
            
            TextField("Departamento", text: $departamento)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
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
            
            TextEditor(text: $indicaciones)
                .font(.custom("Barlow", size: 16))
                .bold()
                .frame(minHeight: 70, maxHeight: 70) // ≈ 3 líneas
                .padding(8)
                .background(Color.blanco)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
                .onChange(of: indicaciones) { oldValue, newValue in
                    if newValue.count > 100 {
                        indicaciones = String(newValue.prefix(100))
                    }
                }
        }
        .padding(.horizontal, 16)
        
        HStack {
            Spacer()
            Button {
                guardarDireccion(direccionViewModel: direccionViewModel)
            } label : {
                Text("Guardar Dirección")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .frame(width: 250, height: 40)
                    .foregroundColor(.blanco)
                    .background(esFormularioValido() ?
                        .verdePrincipal : .grisSecundario)
                    .cornerRadius(16)
            }
            .disabled(!esFormularioValido())
            Spacer()
        }
    }
    
    private func esFormularioValido() -> Bool {
        return !calle.isEmpty && !numero.isEmpty
    }
    
    private func guardarDireccion(direccionViewModel: DireccionViewModel) {
        Task {
            //await direccionViewModel.guardarDireccion(
                
            //)
        }
    }
}
