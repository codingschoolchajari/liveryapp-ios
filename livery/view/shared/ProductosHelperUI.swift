//
//  ProductosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct ProductoMiniatura: View {
    let producto: Producto
    let onMostrarBottomSheet: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? ""))) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.grisSurface
                    }
                }
                .frame(width: 100, height: 100)
                .background(Color.blanco)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Rectángulo de descuento
                if let descuento = producto.descuento, descuento > 0 {
                    RectanguloDescuento(producto: producto, redondeado: 12)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: 100, height: 100)
            
            Spacer().frame(height: 4)
            
            Text(producto.nombre)
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 4)
            
            // 3. Precios
            if producto.precio > 0 {
                VStack(spacing: 4) {
                    // Precio actual
                    Text(DoubleUtils.formatearPrecio(valor: producto.precio))
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                    
                    // Precio anterior (tachado)
                    if let descuento = producto.descuento,
                       let precioSinDescuento = producto.precioSinDescuento,
                       descuento > 0
                    {
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(.grisSecundario)
                            .strikethrough(true, color: .grisSecundario)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .frame(width: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onMostrarBottomSheet()
        }
    }
}

struct Seleccionables: View {
    let categoria: Categoria
    let producto: Producto
    let seleccionadosUnitarios: [String: Bool]
    let seleccionadosMultiples: [String: Int]
    
    var onCambiarSeleccionadoUnitario: (String, Bool) -> Void
    var onCambiarSeleccionadoMultiple: (String, Int) -> Void
    
    @State private var mensajeToast: String? = nil
    @State private var toastWorkItem: DispatchWorkItem? = nil // Para controlar el tiempo

    var body: some View {
        let itemsDisponibles = (categoria.seleccionables ?? [])
            .filter { $0.disponible }
            .sorted(by: { $0.nombre < $1.nombre })
        
        ScrollView (showsIndicators: false){
            VStack(spacing: 4) {
                ForEach(itemsDisponibles, id: \.idInterno) { seleccionable in
                    
                    // Obtenemos el estado actual desde los diccionarios recibidos
                    let unitario = seleccionadosUnitarios[seleccionable.idInterno] ?? false
                    let multiple = seleccionadosMultiples[seleccionable.idInterno] ?? 0
                    
                    FilaSeleccionable(
                        seleccionable: seleccionable,
                        seleccionadoUnitario: unitario,
                        seleccionadoMultiple: multiple,
                        onUnitarioChange: { nuevoValor in
                            validarYNotificarUnitario(id: seleccionable.idInterno, nuevoValor: nuevoValor)
                        },
                        onMultipleChange: { nuevaCant in
                            validarYNotificarMultiple(id: seleccionable.idInterno, nuevaCant: nuevaCant)
                        }
                    )
                }
            }
        }
        .frame(maxHeight: 250)
        .overlay(ToastView(mensaje: $mensajeToast), alignment: .bottom)
    }
    
    private func validarYNotificarUnitario(id: String, nuevoValor: Bool) {
        let total = seleccionadosUnitarios.values.count { $0 }
        
        if nuevoValor && total >= (producto.cantidadMaximaSeleccionables ?? 0) {
            mostrarToast()
        } else {
            onCambiarSeleccionadoUnitario(id, nuevoValor)
        }
    }
    
    private func validarYNotificarMultiple(id: String, nuevaCant: Int) {
        let total = seleccionadosMultiples.values.reduce(0, +)
        let actual = seleccionadosMultiples[id] ?? 0
        
        // Si intenta incrementar y ya llegó al máximo
        if nuevaCant > actual && total >= (producto.cantidadMaximaSeleccionables ?? 0) {
            mostrarToast()
        } else {
            onCambiarSeleccionadoMultiple(id, nuevaCant)
        }
    }
    
    private func mostrarToast() {
        let texto = "Solo puedes seleccionar hasta \(producto.cantidadMaximaSeleccionables ?? 0) \(producto.nombreSeleccionable ?? "")."
        
        // 1. Cancelar cualquier temporizador que esté corriendo
        toastWorkItem?.cancel()
        
        // 2. Asignar el mensaje
        withAnimation {
            mensajeToast = texto
        }
        
        // 3. Crear una nueva tarea para ocultar el toast
        let task = DispatchWorkItem {
            withAnimation {
                self.mensajeToast = nil
            }
        }
        
        // 4. Guardar y programar la tarea
        toastWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
    }
}

struct FilaSeleccionable: View {
    let seleccionable: Seleccionable
    let seleccionadoUnitario: Bool
    let seleccionadoMultiple: Int
    var onUnitarioChange: (Bool) -> Void
    var onMultipleChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(seleccionable.nombre)
                    .font(.custom("Barlow", size: 16))
                    .bold(seleccionadoUnitario || seleccionadoMultiple > 0)
                    .foregroundColor(.negro)
                Spacer()
                
                if seleccionable.tipo == "unitario" {
                    Toggle("", isOn:
                        Binding(
                            get: { seleccionadoUnitario },
                            set: { onUnitarioChange($0) }
                        )
                    )
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                } else {
                    // Selector de cantidad (+ / -)
                    HStack(spacing: 15) {
                        Button(
                            action: {
                                if seleccionadoMultiple > 0 { onMultipleChange(seleccionadoMultiple - 1)
                                }
                            }
                        ) {
                            Text("-")
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(.negro)
                                .frame(width: 20, height: 20)
                        }
                        Text("\(seleccionadoMultiple)")
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(.negro)
                            .frame(width: 16)
                        
                        Button(
                            action: {
                                onMultipleChange(seleccionadoMultiple + 1)
                            }
                        ) {
                            Text("+")
                                .font(.custom("Barlow", size: 16))
                                .bold()
                                .foregroundColor(.negro)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.grisSurface)
                    .cornerRadius(20)
                }
            }
            Divider().background(.grisSurface)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if seleccionable.tipo == "unitario" { onUnitarioChange(!seleccionadoUnitario) }
        }
    }
}
