//
//  ComentarioTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 03/01/2026.
//
import SwiftUI

struct ComentarioTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var cantidadEstrellas: Int = 0
    @State private var textoComentario: String = ""
    @State private var mensajeToast: String? = nil
    
    var body: some View {
        let pedido = pedidosViewModel.pedidoSeleccionado
        let estadoPedido = EstadoPedido.desdeString(pedido?.estado?.nombre ?? "")
        
        ZStack {
            VStack {
                if estadoPedido == .entregado {
                    VStack(spacing: 16) {
                        
                        // ⭐ Estrellas clickeables
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { i in
                                let seleccionada = i <= cantidadEstrellas
                                let camposEnabled = pedido?.comentario == nil
                                
                                Image(seleccionada ? "icono_estrella_relleno" : "icono_estrella_vacio")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(seleccionada ? .verdePrincipal : .negro)
                                    .onTapGesture {
                                        if camposEnabled {
                                            cantidadEstrellas = i
                                        }
                                    }
                            }
                        }
                        .padding(.top, 16)

                        let camposEnabled = pedido?.comentario == nil
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextEditor(text: $textoComentario)
                                .scrollContentBackground(.hidden)
                                .background(Color.blanco)
                                .tint(.verdePrincipal)
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(.negro)
                                .frame(minHeight: 70, maxHeight: 70)
                                .padding(8)
                                .disabled(!camposEnabled)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.grisSecundario, lineWidth: 1)
                                )
                                .onChange(of: textoComentario) { oldValue, newValue in
                                    if newValue.count > 100 {
                                        textoComentario = String(newValue.prefix(100))
                                    }
                                }
                        }

                        // Botón Enviar
                        let botonEnabled = cantidadEstrellas > 0 && !textoComentario.trimmingCharacters(in: .whitespaces).isEmpty && pedido?.comentario == nil
                        
                        Button(action: {
                            enviarComentario()
                        }) {
                            Text("Enviar Comentario")
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(botonEnabled ? .blanco : .grisSecundario)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(botonEnabled ? Color.verdePrincipal : Color.grisSurface)
                                .clipShape(Capsule())
                        }
                        .disabled(!botonEnabled)
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .padding(16)
                    .onAppear {
                        // Inicializar con datos existentes si ya hay un comentario
                        if let comentarioExistente = pedido?.comentario {
                            cantidadEstrellas = comentarioExistente.cantidadEstrellas
                            textoComentario = comentarioExistente.texto
                        }
                    }
                } else {
                    // Estado no entregado
                    Text("Esta sección se habilitará cuando el pedido haya sido entregado.")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
            
            ToastView(mensaje: $mensajeToast)
        }
    }

    private func enviarComentario() {
        Task {
            // 1. Enviar el comentario
            pedidosViewModel.enviarComentario(
                estrellas: cantidadEstrellas,
                texto: textoComentario,
                nombreUsuario: perfilUsuarioState.usuario?.datosPersonales?.nombre ?? ""
            )
            
            // 2. Mostrar el toast con animación
            withAnimation {
                mensajeToast = "Gracias por el comentario"
            }
            
            // 3. Esperar 2 segundos (equivalente a asyncAfter)
            // 2_000_000_000 nanosegundos = 2 segundos
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // 4. Limpiar toast y refrescar
            withAnimation {
                mensajeToast = nil
            }
            
            // Como estamos en un Task de UI, esto ya corre en el hilo principal
            if(pedidosViewModel.pedidoSeleccionado != nil) {
                await pedidosViewModel.refrescarPedidoSeleccionado(pedido: pedidosViewModel.pedidoSeleccionado!)
            }
        }
    }
}
