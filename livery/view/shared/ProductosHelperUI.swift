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
                RemoteImage(
                    url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? "")),
                    fallbackURL: URL(string: API.baseURL + "/" + imagenPorDefectoURL(producto.imagenURL))
                )
                .frame(width: 100, height: 100)
                .background(Color.blanco)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Rectángulo de descuento
                if let descuento = producto.descuento, descuento > 0 {
                    RectanguloDescuento(
                        descuento: descuento,
                        redondeado: 12
                    )
                    .padding(.bottom, 4)
                }
                
                // Rectángulo de descuento para productos con alternativas
                if producto.alternativas.count > 0 &&
                    producto.alternativas.first?.descuento != nil &&
                    (producto.alternativas.first?.descuento)! > 0
                {
                    VStack {
                        Spacer()
                        RectanguloDescuento(
                            descuento: producto.alternativas[0].descuento!,
                            redondeado: 12
                        )
                        .padding(.bottom, 4)
                    }
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
            // 4. Precio para Productos con Alternativas
            if (!producto.alternativas.isEmpty && producto.alternativas[0].precio > 0) {
                VStack(spacing: 4) {
                    Text(DoubleUtils.formatearPrecio(valor: producto.alternativas[0].precio))
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                    
                    if let descuento = producto.alternativas[0].descuento,
                       let precioSinDescuento = producto.alternativas[0].precioSinDescuento,
                       descuento > 0 {
                        
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow", size: 14))
                            .foregroundColor(.grisTerciario)
                            .strikethrough(true, color: .grisTerciario)
                    }
                }
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

struct Alternativas: View {
    let producto: Producto
    let alternativasSeleccionadas: [ProductoAlternativa]
    var onCambiarAlternativaSeleccionada: (ProductoAlternativa) -> Void
    
    var body: some View {
        let alternativas = (producto.alternativas)
            .filter { $0.disponible }
        
        ScrollView (showsIndicators: false){
            VStack(spacing: 4) {
                ForEach(alternativas, id: \.idInterno) { alternativa in
                    
                    let seleccionada = alternativasSeleccionadas.contains { $0.idInterno == alternativa.idInterno }
                    VStack(spacing: 0) {
                        HStack {
                            Text(alternativa.nombre)
                                .font(.custom("Barlow", size: 16))
                                .bold(seleccionada)
                                .foregroundColor(.negro)
                            Spacer()
                            Toggle("", isOn:
                                    Binding(
                                        get: { seleccionada },
                                        set: { _,_ in }
                                    )
                            )
                            .toggleStyle(CheckboxToggleStyle())
                            .allowsHitTesting(false)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                        }
                        Divider().background(.grisSurface)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onCambiarAlternativaSeleccionada(alternativa)
                    }
                }
            }
        }
    }
}

struct PersonalizablesSelector: View {
    let personalizables: [ProductoPersonalizables]
    let opcionesSeleccionadas: [String: String]
    var onSeleccionarOpcion: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(personalizables) { personalizable in
                let opcionesDisponibles = (personalizable.opciones ?? []).filter { $0.disponible }
                let soloLectura = personalizable.deshabilitado == true

                if !opcionesDisponibles.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(personalizable.titulo)
                            .font(.custom("Barlow", size: 15))
                            .bold()
                            .foregroundColor(soloLectura ? .grisTerciario : .verdePrincipal)

                        ForEach(opcionesDisponibles) { opcion in
                            let seleccionada = opcionesSeleccionadas[personalizable.idInterno] == opcion.idInterno

                            HStack(alignment: .center, spacing: 0) {
                                Text(opcion.nombre)
                                    .font(.custom("Barlow", size: 14))
                                    .foregroundColor(soloLectura ? .grisSecundario : .negro)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if !soloLectura {
                                    RadioButtonCompacto(
                                        seleccionado: seleccionada,
                                        color: seleccionada ? .verdePrincipal : .grisTerciario
                                    )
                                    .frame(width: 40, height: 28, alignment: .center)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !soloLectura {
                                    onSeleccionarOpcion(personalizable.idInterno, opcion.idInterno)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RadioButtonCompacto: View {
    let seleccionado: Bool
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 18, height: 18)

            if seleccionado {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 18, height: 18)
    }
}

struct ComplementoPopupOpcion: Identifiable {
    let id = UUID().uuidString.lowercased()
    let nombre: String
    let precio: Double
}

struct ComplementoPopupGrupo: Identifiable {
    let idInterno: String
    let nombre: String
    let opciones: [ComplementoPopupOpcion]
    var porProducto: Bool? = nil

    var id: String { idInterno }
}

func construirGruposComplementos(producto: Producto, comercio: Comercio) -> [ComplementoPopupGrupo] {
    guard let complementos = producto.complementos, !complementos.isEmpty else {
        return []
    }

    let productosComercio = comercio.categorias.flatMap { $0.productos }

    return complementos.compactMap { complemento in
        guard let productoComplemento = productosComercio.first(where: { $0.idInterno == complemento.idInterno }) else {
            return nil
        }

        var opciones: [ComplementoPopupOpcion] = [
            ComplementoPopupOpcion(nombre: "Sin \(complemento.nombre)", precio: 0.0)
        ]

        if let personalizables = productoComplemento.personalizables, !personalizables.isEmpty {
            for personalizable in personalizables {
                let opcionesPersonalizable = (personalizable.opciones ?? []).filter { $0.disponible }
                for opcion in opcionesPersonalizable {
                    opciones.append(
                        ComplementoPopupOpcion(
                            nombre: opcion.nombre,
                            precio: productoComplemento.precio
                        )
                    )
                }
            }
        } else if !productoComplemento.alternativas.isEmpty {
            for alternativa in productoComplemento.alternativas where alternativa.disponible {
                opciones.append(
                    ComplementoPopupOpcion(
                        nombre: alternativa.nombre,
                        precio: alternativa.precio
                    )
                )
            }
        } else if productoComplemento.disponible {
            opciones.append(
                ComplementoPopupOpcion(
                    nombre: productoComplemento.nombre,
                    precio: productoComplemento.precio
                )
            )
        }

        if opciones.count > 1 {
            return ComplementoPopupGrupo(
                idInterno: complemento.idInterno,
                nombre: complemento.nombre,
                opciones: opciones,
                porProducto: complemento.porProducto
            )
        }

        return nil
    }
}

func calcularPrecioExtraComplementos(
    grupos: [ComplementoPopupGrupo],
    selecciones: [String: [Int]],
    procesosExtras: [String] = []
) -> Double {
    var preciosSeleccionados: [Double] = []

    for grupo in grupos {
        let seleccionGrupo = selecciones[grupo.idInterno] ?? []
        for indiceOpcion in seleccionGrupo {
            guard grupo.opciones.indices.contains(indiceOpcion) else { continue }
            let precio = grupo.opciones[indiceOpcion].precio
            if precio > 0 {
                preciosSeleccionados.append(precio)
            }
        }
    }

    if preciosSeleccionados.isEmpty {
        return 0.0
    }

    if procesosExtras.contains("dos-por-uno-complementos") {
        return preciosSeleccionados.max() ?? 0.0
    }

    return preciosSeleccionados.reduce(0.0, +)
}

func construirResumenComplementos(
    grupos: [ComplementoPopupGrupo],
    selecciones: [String: [Int]],
    nombresSeleccionablesPorFila: [String] = []
) -> [String] {
    let gruposNormales = grupos.filter { $0.porProducto != true }
    let gruposPorProducto = grupos.filter { $0.porProducto == true }

    let cantidadFilas = max(
        gruposNormales.map { selecciones[$0.idInterno]?.count ?? 0 }.max() ?? 0,
        nombresSeleccionablesPorFila.count
    )

    let lineasSeleccionables: [String] = (0..<cantidadFilas).compactMap { indiceFila in
        let nombreSeleccionable = nombresSeleccionablesPorFila.indices.contains(indiceFila)
            ? nombresSeleccionablesPorFila[indiceFila]
            : nil

        let descripcionesComplementos = gruposNormales.compactMap { grupo -> String? in
            guard let indiceOpcion = selecciones[grupo.idInterno]?[safe: indiceFila],
                  grupo.opciones.indices.contains(indiceOpcion) else { return nil }
            let opcion = grupo.opciones[indiceOpcion]
            if indiceOpcion == 0 { return "sin \(grupo.nombre)" }
            return "con \(opcion.nombre)"
        }

        let partes = [nombreSeleccionable, descripcionesComplementos.isEmpty ? nil : descripcionesComplementos.joined(separator: ", ")]
            .compactMap { $0 }
        let linea = partes.joined(separator: " ")
        return linea.isEmpty ? nil : linea
    }

    let lineasPorProducto: [String] = gruposPorProducto.compactMap { grupo in
        guard let indiceOpcion = selecciones[grupo.idInterno]?[safe: 0],
              indiceOpcion > 0,
              grupo.opciones.indices.contains(indiceOpcion) else { return nil }
        return grupo.opciones[indiceOpcion].nombre
    }

    return lineasSeleccionables + lineasPorProducto
}

func construirResumenPreciosComplementos(
    grupos: [ComplementoPopupGrupo],
    selecciones: [String: [Int]],
    procesosExtras: [String] = []
) -> [String] {
    var preciosSeleccionados: [Double] = []

    for grupo in grupos {
        let seleccionGrupo = selecciones[grupo.idInterno] ?? []
        for indiceOpcion in seleccionGrupo {
            guard grupo.opciones.indices.contains(indiceOpcion) else { continue }
            let precio = grupo.opciones[indiceOpcion].precio
            if precio > 0 {
                preciosSeleccionados.append(precio)
            }
        }
    }

    if procesosExtras.contains("dos-por-uno-complementos") {
        guard let precioCobrado = preciosSeleccionados.max() else {
            return []
        }
        return ["1  x  \(DoubleUtils.formatearPrecio(valor: precioCobrado))"]
    }

    let agrupados = Dictionary(grouping: preciosSeleccionados, by: { $0 })
        .mapValues { $0.count }

    return agrupados
        .sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }
            return lhs.value > rhs.value
        }
        .map { "\($0.value)  x  \(DoubleUtils.formatearPrecio(valor: $0.key))" }
}

struct DialogoSeleccionComplementos: View {
    let nombreProducto: String
    let nombresSeleccionablesPorFila: [String]
    let grupos: [ComplementoPopupGrupo]
    let selecciones: [String: [Int]]
    let precioTotal: Double
    let personalizables: [ProductoPersonalizables]?
    let opcionesPersonalizablesSeleccionadas: [String: String]
    var onSeleccionar: (String, Int, Int) -> Void
    var onDismiss: () -> Void
    var onConfirmar: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(grupos.enumerated()), id: \ .element.idInterno) { indiceGrupo, grupo in
                            Text("¿Querés agregarle \(grupo.nombre)?")
                                .font(.custom("Barlow", size: 14))
                                .bold()
                                .foregroundColor(.negro)
                                .frame(maxWidth: .infinity, alignment: .center)

                            let seleccionGrupo = selecciones[grupo.idInterno] ?? []
                            ForEach(Array(seleccionGrupo.enumerated()), id: \ .offset) { indiceFila, indiceOpcion in
                                let nombreFila: String
                                if grupo.porProducto == true {
                                    nombreFila = nombreProducto
                                } else {
                                    nombreFila = nombresSeleccionablesPorFila.indices.contains(indiceFila)
                                        ? nombresSeleccionablesPorFila[indiceFila]
                                        : nombreProducto
                                }
                                SelectorComplementoPorUnidad(
                                    nombreProducto: nombreFila,
                                    personalizables: personalizables,
                                    opcionesPersonalizablesSeleccionadas: opcionesPersonalizablesSeleccionadas,
                                    opciones: grupo.opciones,
                                    indiceSeleccionado: indiceOpcion,
                                    onSeleccionar: { nuevoIndice in
                                        onSeleccionar(grupo.idInterno, indiceFila, nuevoIndice)
                                    }
                                )
                            }

                            if indiceGrupo < grupos.count - 1 {
                                Divider()
                                    .background(Color.grisSecundario)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                }

                Spacer().frame(height: 12)

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.grisSurface)
                        .frame(height: 45)

                    Text(DoubleUtils.formatearPrecio(valor: precioTotal))
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(.negro)
                }

                Spacer().frame(height: 10)

                HStack(spacing: 8) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Cancelar")
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(.negro)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.grisSurface)
                            .cornerRadius(16)
                    }

                    Button(action: {
                        onConfirmar()
                    }) {
                        Text("Confirmar")
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(.blanco)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.verdePrincipal)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
            .background(Color.blanco)
            .cornerRadius(18)
            .onTapGesture { }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct SelectorComplementoPorUnidad: View {
    let nombreProducto: String
    let personalizables: [ProductoPersonalizables]?
    let opcionesPersonalizablesSeleccionadas: [String: String]
    let opciones: [ComplementoPopupOpcion]
    let indiceSeleccionado: Int
    var onSeleccionar: (Int) -> Void

    private var nombreProductoConPersonalizable: String {
        guard let personalizables, !personalizables.isEmpty else {
            return nombreProducto
        }

        for personalizable in personalizables {
            guard let idSeleccionado = opcionesPersonalizablesSeleccionadas[personalizable.idInterno] else {
                continue
            }

            if let nombreOpcion = personalizable.opciones?.first(where: { $0.idInterno == idSeleccionado })?.nombre {
                return "\(nombreProducto) - \(nombreOpcion)"
            }
        }

        return nombreProducto
    }

    var body: some View {
        let opcionSeleccionada = opciones.indices.contains(indiceSeleccionado) ? opciones[indiceSeleccionado] : opciones.first

        HStack(spacing: 8) {
            Text(nombreProductoConPersonalizable)
                .font(.custom("Barlow", size: 13))
                .foregroundColor(.negro)
                .lineLimit(1)

            Spacer(minLength: 8)

            Menu {
                ForEach(Array(opciones.enumerated()), id: \ .offset) { index, opcion in
                    Button(action: {
                        onSeleccionar(index)
                    }) {
                        let textoPrecio = opcion.precio > 0 ? " (+\(DoubleUtils.formatearPrecio(valor: opcion.precio)))" : ""
                        Text("\(opcion.nombre)\(textoPrecio)")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(opcionSeleccionada?.nombre ?? "")
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(.negro)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.negro)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.blanco)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
}
