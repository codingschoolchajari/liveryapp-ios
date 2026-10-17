//
//  ComentarioPopupView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 17/10/2026.
//
import SwiftUI

struct ComentarioPopupView: View {
    let pedido: Pedido
    let nombreUsuario: String
    @ObservedObject var viewModel: ComentarioPopupViewModel

    @State private var cantidadEstrellas: Int = 0
    @State private var textoComentario: String = ""
    @State private var cantidadEstrellasRepartidor: Int = 0
    @State private var textoComentarioRepartidor: String = ""

    private var esEnvioLivery: Bool {
        TipoEntrega.desdeString(pedido.tipoEntrega) == .envioLivery
    }

    private var botonEnviarHabilitado: Bool {
        cantidadEstrellas > 0
            && !textoComentario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.enviando
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Título
                Text("Pedido en \(pedido.nombreComercio)")
                    .font(.custom("Barlow", size: 15))
                    .bold()
                    .foregroundColor(.verdePrincipal)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text("¿Querés dejar un Comentario?")
                    .font(.custom("Barlow", size: 15))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Scroll horizontal de productos
                PedidoItemsView(
                    itemsPromociones: pedido.itemsPromociones,
                    itemsProductos: pedido.itemsProductos
                )

                // Comercio
                SelectorEstrellas(
                    cantidad: cantidadEstrellas,
                    enabled: !viewModel.enviando
                ) { cantidadEstrellas = $0 }

                TextEditor(text: $textoComentario)
                    .scrollContentBackground(.hidden)
                    .background(Color.blanco)
                    .tint(.verdePrincipal)
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.negro)
                    .frame(minHeight: 70, maxHeight: 70)
                    .padding(8)
                    .disabled(viewModel.enviando)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )
                    .onChange(of: textoComentario) { oldValue, newValue in
                        textoComentario = normalizarTextoComentario(newValue, max: 100)
                    }

                if esEnvioLivery {
                    // Repartidor (opcional)
                    SelectorEstrellas(
                        cantidad: cantidadEstrellasRepartidor,
                        enabled: !viewModel.enviando
                    ) { cantidadEstrellasRepartidor = $0 }

                    TextEditor(text: $textoComentarioRepartidor)
                        .scrollContentBackground(.hidden)
                        .background(Color.blanco)
                        .tint(.verdePrincipal)
                        .font(.custom("Barlow", size: 16))
                        .bold()
                        .foregroundColor(.negro)
                        .frame(minHeight: 70, maxHeight: 70)
                        .padding(8)
                        .disabled(viewModel.enviando)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.grisSecundario, lineWidth: 1)
                        )
                        .onChange(of: textoComentarioRepartidor) { oldValue, newValue in
                            textoComentarioRepartidor = normalizarTextoComentario(newValue, max: 100)
                        }
                }

                // Botones
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.noDejarComentario()
                    }) {
                        Text("No Dejar Comentario")
                            .font(.custom("Barlow", size: 13))
                            .bold()
                            .foregroundColor(.blanco)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.grisTerciario)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.enviando)

                    Button(action: {
                        enviar()
                    }) {
                        Text("Enviar Comentario")
                            .font(.custom("Barlow", size: 13))
                            .bold()
                            .foregroundColor(botonEnviarHabilitado ? .blanco : .grisSecundario)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(botonEnviarHabilitado ? Color.verdePrincipal : Color.grisSurface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!botonEnviarHabilitado)
                }
                .padding(.horizontal, 16)
            }
            .padding(16)
        }
        .background(Color.blanco)
        .presentationDetents([.fraction(0.75)])
        .interactiveDismissDisabled(true)
        .presentationDragIndicator(.hidden)
    }

    private func enviar() {
        let comentario = Comentario(
            fecha: "",
            texto: normalizarTextoComentario(textoComentario, max: 100),
            nombreUsuario: nombreUsuario,
            cantidadEstrellas: cantidadEstrellas
        )

        let comentarioRepartidor: Comentario? = esEnvioLivery
            ? Comentario(
                fecha: "",
                texto: normalizarTextoComentario(textoComentarioRepartidor, max: 100),
                nombreUsuario: nombreUsuario,
                cantidadEstrellas: cantidadEstrellasRepartidor
            )
            : nil

        viewModel.enviarComentario(comentario: comentario, comentarioRepartidor: comentarioRepartidor)
    }

    private func normalizarTextoComentario(_ texto: String, max: Int) -> String {
        var textoRecortado = texto
        if textoRecortado.count > max {
            textoRecortado = String(textoRecortado.prefix(max))
        }
        guard let first = textoRecortado.first else { return textoRecortado }
        return String(first).uppercased() + textoRecortado.dropFirst().lowercased()
    }
}

private struct SelectorEstrellas: View {
    let cantidad: Int
    let enabled: Bool
    let onSeleccionar: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { i in
                let seleccionada = i <= cantidad
                Image(seleccionada ? "icono_estrella_relleno" : "icono_estrella_vacio")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(seleccionada ? .verdePrincipal : .negro)
                    .onTapGesture {
                        if enabled {
                            onSeleccionar(i)
                        }
                    }
            }
        }
    }
}
