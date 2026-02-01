//
//  CarritoHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct TituloComercio: View {
    let comercio: Comercio
    var mostrarBotonAdd: Bool = true
    
    var body: some View {
        ZStack {
            ComercioTitulo(
                comercio: comercio,
                mostrarBotonAdd: mostrarBotonAdd
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color.blanco)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.grisSecundario, lineWidth: 2)
        )
        .padding(.horizontal, 30)
    }
}

struct CantidadUnidadesYPrecio: View {
    var cambioUnidadesHabilitado: Bool = true
    let cantidad: Int
    let precio: Double?
    var onAumentarCantidad: () -> Void
    var onDisminuirCantidad: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if cambioUnidadesHabilitado {
                HStack {
                    Button(action: {
                        if cantidad > 1 { onDisminuirCantidad() }
                    }) {
                        Text("-")
                            .font(.custom("Barlow", size: 24))
                            .bold()
                            .padding(.horizontal, 8)
                            .foregroundColor(.negro)
                            .frame(width: 30, height: 45)
                    }
                    Text("\(cantidad)")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(.negro)
                        .frame(width: 30)
                    
                    Button(action: {
                        onAumentarCantidad()
                    }) {
                        Text("+")
                            .font(.custom("Barlow", size: 24))
                            .bold()
                            .padding(.horizontal, 8)
                            .foregroundColor(.negro)
                            .frame(width: 30, height: 45)
                    }
                }
                .padding(.horizontal, 8)
                .background(.grisSurface)
                .cornerRadius(24)
                .layoutPriority(1)
            }
            
            ZStack(alignment: cambioUnidadesHabilitado ? .trailing : .center) {
                if let precio = precio {
                    Text(DoubleUtils.formatearPrecio(valor: precio))
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(.negro)
                        .padding(.horizontal, cambioUnidadesHabilitado ? 24 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(.grisSurface)
            .cornerRadius(24)
            .padding(.horizontal, cambioUnidadesHabilitado ? 0 : 75)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AgregarCarrito: View {
    let enabled: Bool
    @Binding var mostrarDialogoConflicto: Bool
    var onConfirmar: () -> Void
    var onConfirmarConflicto: () -> Void
    
    var body: some View {
        Button(action: {
            onConfirmar()
        }) {
            Text("Agregar")
                .font(.custom("Barlow", size: 18))
                .bold()
                .foregroundColor(enabled ? .blanco : .grisSecundario)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(enabled ? Color.verdePrincipal : .grisSurface)
                .cornerRadius(24)
        }
        .disabled(!enabled)
        .padding(.bottom, 8)
        .alert("Productos de otro Comercio", isPresented: $mostrarDialogoConflicto) {
            Button("Cancelar", role: .cancel) { }
            Button("Aceptar") {
                onConfirmarConflicto()
            }
        } message: {
            Text("Solo puedes agregar productos de un mismo comercio al carrito.\n\n¿Deseas vaciar el carrito actual y agregar este producto?")
        }
    }
}
