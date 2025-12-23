//
//  DireccionView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI
import GoogleMaps

struct DatosPersonalesView: View {

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    var body: some View {
        ZStack(alignment: .top) {
            Color(.blanco).ignoresSafeArea()
            
            Color.verdePrincipal
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Formulario de Registro")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(.negro)
                    
                    Text("Información a ser compartida con Comercios y Repartidores para lograr un envío exitoso")
                        .font(.custom("Barlow", size: 16))
                        .bold()
                        .foregroundColor(.blanco)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(Color.verdePrincipal)
                
                // Formulario
                FormularioDatosPersonalesView()
                
                Spacer()
            }
        }
    }
}

struct FormularioDatosPersonalesView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    @State private var nombre: String = ""
    @State private var apellido: String = ""
    @State private var dni: String = ""
    @State private var mostrarAlerta = false

    var body: some View {
        VStack(spacing: 8) {
            TextField("Nombre", text: $nombre)
                .tint(.verdePrincipal)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
                .background(Color.blanco)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.negro, lineWidth: 1)
                )
            
            TextField("Apellido", text: $apellido)
                .tint(.verdePrincipal)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
                .background(Color.blanco)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.negro, lineWidth: 1)
                )
            
            TextField("DNI", text: $dni)
                .tint(.verdePrincipal)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
                .background(Color.blanco)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.negro, lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        
        HStack {
            Spacer()
            Button(action: {
                Task {
                    await perfilUsuarioState.actualizarDatosPersonales(
                        nombre: nombre,
                        apellido: apellido,
                        dni: Int(dni) ?? 0
                    )
                    mostrarAlerta = true
                }
            }) {
                Text("Confirmar Datos")
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
        // Diálogo de Confirmación (Alert en iOS)
        .alert("Gracias", isPresented: $mostrarAlerta) {
            Button("OK") {
                Task {
                    await perfilUsuarioState.buscarUsuario()
                }
            }
        } message: {
            Text("Datos cargados correctamente")
        }
    }
    
    private func esFormularioValido() -> Bool {
        return
            !nombre.trimmingCharacters(in: .whitespaces).isEmpty &&
            !apellido.trimmingCharacters(in: .whitespaces).isEmpty &&
            !dni.isEmpty
    }
}
