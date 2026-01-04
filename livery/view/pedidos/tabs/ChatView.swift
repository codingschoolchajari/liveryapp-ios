//
//  ChatView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI

struct ChatView: View {
    @ObservedObject var pedidoChatViewModel: PedidoChatViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var texto: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Lista de Mensajes (LazyColumn)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(pedidoChatViewModel.mensajes) { mensaje in
                            MensajeRow(mensaje: mensaje, emailUsuario: perfilUsuarioState.usuario?.email ?? "")
                                .id(mensaje.id) // Necesario para el auto-scroll
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: pedidoChatViewModel.mensajes.count) {
                    scrollToBottom(proxy: proxy)
                }
                // Scroll automático cuando aparece el teclado
                .onChange(of: isFocused) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // Input de Texto (TextField)
            HStack(spacing: 8) {
                TextField("", text: $texto)
                    .tint(.verdePrincipal)
                    .disableAutocorrection(true)
                    .autocapitalization(.sentences)
                    .font(.custom("Barlow", size: 14))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .foregroundColor(Color.grisTerciario)
                    .background(Color.grisSurface)
                    .cornerRadius(22)
                    .focused($isFocused)
                    .overlay(
                        Group {
                            if texto.isEmpty {
                                Text("Escribir mensaje…")
                                    .font(.custom("Barlow", size: 14))
                                    .foregroundColor(Color.grisTerciario)
                                    .padding(.horizontal, 16)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .leading
                    )
                    .onChange(of: texto) { oldValue, newValue in
                        procesarEntradaTexto(newValue)
                    }
                
                Button(action: enviarMensaje) {
                    Image("icono_enviar")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(Color.negro)
                }
                .disabled(texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 16)
        }
        // Manejo de Error (AlertDialog)
        .alert("Chat no disponible", isPresented: Binding(
            get: { pedidoChatViewModel.errorMensaje != nil },
            set: { _ in pedidoChatViewModel.limpiarError() }
        )) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(pedidoChatViewModel.errorMensaje ?? "")
        }
    }
    
    // Lógica de validación del TextField
    private func procesarEntradaTexto(_ newValue: String) {
        var result = newValue.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }
        if result.count <= 100 {
            texto = result
        } else {
            texto = String(result.prefix(100))
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = pedidoChatViewModel.mensajes.last?.timestamp {
            withAnimation {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
    
    private func enviarMensaje() {
        
        let usuario = perfilUsuarioState.usuario
        if (usuario == nil || usuario?.email == nil) { return }
        
        let emisorNombre = "\(usuario!.datosPersonales?.nombre ?? "") \(usuario!.datosPersonales?.apellido ?? "")"
        let nuevoMensaje = Mensaje(texto: texto, emisorId: usuario!.email, emisorNombre: emisorNombre)
        
        pedidoChatViewModel.enviarMensaje(mensaje: nuevoMensaje)
        texto = ""
    }
}

struct MensajeRow: View {
    let mensaje: Mensaje
    let emailUsuario: String
    
    var body: some View {
        // Determinamos si el mensaje fue enviado por el usuario actual
        let esMio = mensaje.emisorId == emailUsuario
        
        HStack {
            if esMio { Spacer(minLength: 40) } // Empuja el mensaje a la derecha
            
            VStack(alignment: .leading, spacing: 4) {
                // Nombre del emisor
                Text(mensaje.emisorNombre)
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(esMio ? Color.verdePrincipal : Color.grisTerciario)
                    
                Text(mensaje.texto)
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(esMio ? .blanco : .negro)
 
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                esMio ?
                Color.verdeMensajeUsuario :
                Color.grisSurface
            )
            .clipShape(
                RoundedCorners(
                    radius: 22,
                    corners: [.topLeft, .topRight, .bottomLeft, .bottomRight]
                )
            )
            
            if !esMio { Spacer(minLength: 40) } // Empuja el mensaje a la izquierda
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
}
