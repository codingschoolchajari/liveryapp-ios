//
//  ProductoView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct ProductoTitulo: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    let producto: Producto
    let categoria: Categoria
    let onSelect: () -> Void
    var displayIndex: Int = 0
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var esFavorito: Bool = false
    
    var body: some View {
        let comercio = comercioViewModel.comercio
        let descripcionesHorariosReducidos = comercio != nil
            ? DateUtils.obtenerDescripcionesHorariosReducidosProducto(producto: producto, comercio: comercio!)
            : []
        let idFavorito = perfilUsuarioState.usuario?.obtenerIdProductoFavorito(
            idComercio: comercio?.idInterno,
            idProducto: producto.idInterno
        )
        
        ZStack {
            HStack(spacing: 8) {
                ProductoDescripcion(
                    producto: producto,
                    productoAlternativa: !producto.alternativas.isEmpty && (producto.cantidadMinimaAlternativasSeleccionables ?? 1) <= 1 ? producto.alternativas.first : nil,
                    descripcionesHorariosReducidos: descripcionesHorariosReducidos
                )
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .center) {
                    RemoteImage(
                        url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? "")),
                        fallbackURL: URL(string: API.baseURL + "/" + imagenPorDefectoURL(producto.imagenURL)),
                        displayIndex: displayIndex
                    )
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        if let colorBordeStr = comercio?.colorBorde, !colorBordeStr.isEmpty,
                           let borderColor = Color(hexString: colorBordeStr) {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(borderColor, lineWidth: 1)
                        }
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                if(comercio != nil){
                                    toggleFavorito(comercio: comercio!, idFavorito: idFavorito)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 25, height: 25)
                                    Image(esFavorito ? "icono_favoritos_relleno" : "icono_favoritos_vacio")
                                        .resizable()
                                        .renderingMode(.template)
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(esFavorito ? .verdePrincipal : .negro)
                                }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                    
                    if let descuento = producto.descuento, descuento > 0 {
                        VStack {
                            Spacer()
                            RectanguloDescuento(
                                descuento: descuento,
                                redondeado: 12
                            )
                            .padding(.bottom, 4)
                        }
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
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color.blanco)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
        }
        .onAppear {
            esFavorito = (idFavorito != nil)
        }
    }
    
    private func toggleFavorito(comercio: Comercio, idFavorito: String?) {
        esFavorito.toggle()
        Task {
            if esFavorito {
                await perfilUsuarioState.agregarFavorito(
                    idFavorito: UUID().uuidString.lowercased(),
                    idComercio: comercio.idInterno,
                    nombreComercio: comercio.nombre,
                    logoComercioURL: comercio.logoURL,
                    idProducto: producto.idInterno,
                    idPromocion: nil,
                    nombre: producto.nombre,
                    imagenURL: producto.imagenURL
                )
            } else if let idFav = idFavorito {
                await perfilUsuarioState.eliminarFavorito(idFavorito: idFav)
            }
        }
    }
}

struct ProductoDescripcion: View {
    let producto: Producto
    let productoAlternativa: ProductoAlternativa?
    var descripcionesHorariosReducidos: [String] = []
    
    // Valores por defecto
    var fontSizeNombre: CGFloat = 16
    var fontSizePrecio: CGFloat = 18
    var fontSizeDescripcion: CGFloat = 14
    var maxDescripcionLines: Int = 2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(producto.nombre)
                .font(.custom("Barlow", size: fontSizeNombre))
                .bold()
                .foregroundColor(.negro)
            
            if !producto.descripcion.isEmpty {
                Text(producto.descripcion)
                    .font(.custom("Barlow", size: fontSizeDescripcion))
                    .foregroundColor(.negro)
                    .lineLimit(maxDescripcionLines)
                    .truncationMode(.tail)
            }
            
            if producto.precio > 0 {
                HStack(alignment: .center, spacing: 8) {
                    Text(DoubleUtils.formatearPrecio(valor: producto.precio))
                        .font(.custom("Barlow", size: fontSizePrecio))
                        .bold()
                        .foregroundColor(.negro)
                    
                    if let descuento = producto.descuento,
                       let precioSinDescuento = producto.precioSinDescuento,
                       descuento > 0 {
                        
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow", size: fontSizePrecio))
                            .foregroundColor(.grisTerciario)
                            .strikethrough(true, color: .grisTerciario)
                    }
                }
            }
            
            if productoAlternativa != nil && productoAlternativa!.precio > 0 {
                HStack(alignment: .center, spacing: 8) {
                    Text(DoubleUtils.formatearPrecio(valor: productoAlternativa!.precio))
                        .font(.custom("Barlow", size: fontSizePrecio))
                        .bold()
                        .foregroundColor(.negro)
                    
                    if let descuento = productoAlternativa!.descuento,
                       let precioSinDescuento = productoAlternativa!.precioSinDescuento,
                       descuento > 0 {
                        
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow", size: fontSizePrecio))
                            .foregroundColor(.grisTerciario)
                            .strikethrough(true, color: .grisTerciario)
                    }
                }
            }

            if !descripcionesHorariosReducidos.isEmpty {
                Text("Disponible en \(descripcionesHorariosReducidos.joined(separator: " / "))")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

struct RectanguloDescuento: View {
    let descuento: Int
    var fontSizeDescuento: CGFloat = 14
    var redondeado: CGFloat = 8
    
    var body: some View {
        Text("\(descuento) % OFF")
            .font(.custom("Barlow", size: fontSizeDescuento))
            .bold()
            .foregroundColor(.negro)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Color.amarilloDescuento
                    .cornerRadius(redondeado)
            )
    }
}

struct BottomSheetSeleccionProducto: View {
    let producto: Producto
    let categoria: Categoria
    let comercio: Comercio
    let onClose: () -> Void
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    @StateObject private var itemProductoViewModel = ItemProductoViewModel()
    
    @State private var mostrarDialogoConflicto = false
    @State private var mensajeToast: String? = nil
    @State private var mostrarLoginRequerido = false
    @State private var mostrarDialogoComplementos = false
    @State private var mostrarDialogoHorarioReducido = false
    @State private var mensajeDialogoHorarioReducido = ""
    @State private var mostrarDialogoMenuNoDisponible = false
    @State private var mensajeDialogoMenuNoDisponible = ""
    @State private var mostrarPopupDni = false
    @State private var dniIngresado = ""
    @State private var guardandoDni = false
    @State private var accionPendienteDni: (() -> Void)? = nil
    @State private var itemPendienteAgregar: ItemProducto? = nil
    @State private var limpiarCarritoEnConfirmacion = false
    @State private var gruposComplementos: [ComplementoPopupGrupo] = []
    @State private var seleccionesComplementos: [String: [Int]] = [:]
    @State private var nombresSeleccionablesComplementos: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            let esPremio: Bool = producto.esPremio ?? false
            let requiereSeleccionables = (producto.cantidadMinimaSeleccionables ?? 0) > 0 && categoria.seleccionables != nil
            let tieneAlternativas = !producto.alternativas.isEmpty && !esPremio

            // 1. Portada (Ocupa 3/4 del ancho de pantalla)
            PortadaProducto(
                producto: producto,
                productoAlternativa: esPremio ? nil : itemProductoViewModel.alternativaParaDescripcion
            )
            
            // 2. Bloque Central scrolleable (Descripción + configuraciones)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 12)

                    ProductoDescripcion(
                        producto: producto,
                        productoAlternativa: esPremio ? nil : itemProductoViewModel.alternativaParaDescripcion,
                        descripcionesHorariosReducidos: DateUtils.obtenerDescripcionesHorariosReducidosProducto(producto: producto, comercio: comercio),
                        fontSizeNombre: 20,
                        fontSizePrecio: 22,
                        fontSizeDescripcion: 16,
                        maxDescripcionLines: 5
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let desc = producto.descripcionDetallada, !desc.isEmpty {
                        Spacer().frame(height: 8)
                        Text(parsearTextoFormateado(desc, fontSize: 16))
                            .font(.custom("Barlow", size: 16))
                            .foregroundColor(.negro)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let personalizables = producto.personalizables, !personalizables.isEmpty {
                        Spacer().frame(height: 24)

                        PersonalizablesSelector(
                            personalizables: personalizables,
                            opcionesSeleccionadas: itemProductoViewModel.opcionesPersonalizablesSeleccionadas,
                            onSeleccionarOpcion: { idPersonalizable, idOpcion in
                                itemProductoViewModel.seleccionarOpcionPersonalizable(
                                    idPersonalizable: idPersonalizable,
                                    idOpcion: idOpcion
                                )
                            }
                        )

                        if tieneAlternativas || requiereSeleccionables {
                            Divider()
                                .frame(height: 3)
                                .overlay(Color.gray.opacity(0.3))
                                .padding(.top, 8)
                        }
                    }

                    Spacer().frame(height: 12)

                    if requiereSeleccionables {
                        Seleccionables(
                            categoria: categoria,
                            producto: producto,
                            seleccionadosUnitarios: itemProductoViewModel.seleccionadosUnitarios,
                            seleccionadosMultiples: itemProductoViewModel.seleccionadosMultiples,
                            onCambiarSeleccionadoUnitario: { id, valor in
                                itemProductoViewModel.cambiarSeleccionadoUnitario(
                                    perfilUsuarioState: perfilUsuarioState,
                                    id: id,
                                    seleccionadoUnitario: valor
                                )
                            },
                            onCambiarSeleccionadoMultiple: { id, cant in
                                itemProductoViewModel.cambiarSeleccionadoMultiple(
                                    perfilUsuarioState: perfilUsuarioState,
                                    id: id,
                                    cantidad: cant
                                )
                            }
                        )
                    } else if tieneAlternativas {
                        Alternativas(
                            producto: producto,
                            alternativasSeleccionadas: itemProductoViewModel.alternativasSeleccionadas,
                            onCambiarAlternativaSeleccionada: { alternativa in
                                itemProductoViewModel.cambiarAlternativaSeleccionada(productoAlternativa: alternativa)
                            }
                        )
                    }

                    Spacer().frame(height: 12)
                }
                .padding(.horizontal, 16)
            }

            let item = itemProductoViewModel.itemProducto
            let esMultiSelect = (producto.cantidadMaximaAlternativasSeleccionables ?? 1) > 1
            let minAlt = producto.cantidadMinimaAlternativasSeleccionables ?? 0
            let enabledAlt = !esMultiSelect || itemProductoViewModel.alternativasSeleccionadas.count >= minAlt
            let cambioUnidadesHabilitado = requiereSeleccionables ? false : (tieneAlternativas ? true : producto.esPremio != true)
            let tienePersonalizables = !(producto.personalizables ?? []).isEmpty
            let personalizablesValidos = !tienePersonalizables || !itemProductoViewModel.opcionesPersonalizablesSeleccionadas.isEmpty
            let botonHabilitado = personalizablesValidos && (requiereSeleccionables ? calcularSiEstaHabilitado() : (tieneAlternativas ? enabledAlt : calcularSiEstaHabilitado()))

            VStack(spacing: 4) {
                CantidadUnidadesYPrecio(
                    cambioUnidadesHabilitado: cambioUnidadesHabilitado,
                    cantidad: itemProductoViewModel.cantidad,
                    precio: item?.precio,
                    onAumentarCantidad: { itemProductoViewModel.aumentarCantidad() },
                    onDisminuirCantidad: { itemProductoViewModel.disminuirCantidad() }
                )

                AgregarCarrito(
                    enabled: botonHabilitado,
                    mostrarDialogoConflicto: $mostrarDialogoConflicto,
                    onConfirmar: { agregarItemProducto(onClose: onClose) },
                    onConfirmarConflicto: { limpiarYAgregarItemProducto(onClose: onClose) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onAppear {
            itemProductoViewModel.inicializar(producto: producto, categoria: categoria, comercio: comercio)
        }
        .sheet(isPresented: $mostrarLoginRequerido) {
            LoginRequiridoView {
                mostrarLoginRequerido = false
            }
            .presentationDetents([.fraction(0.75)])
        }
        .overlay {
            if mostrarPopupDni {
                PopupDniGridoView(
                    nombreComercio: comercio.nombre,
                    dni: $dniIngresado,
                    guardando: guardandoDni,
                    onNoGracias: {
                        mostrarPopupDni = false
                        let accionPendiente = accionPendienteDni
                        accionPendienteDni = nil
                        dniIngresado = ""
                        accionPendiente?()
                    },
                    onConfirmar: {
                        Task {
                            guardandoDni = true
                            let actualizado = await perfilUsuarioState.actualizarDni(dni: dniIngresado)
                            guardandoDni = false

                            if !actualizado {
                                mensajeToast = "No pudimos guardar tu DNI. Continuamos igualmente."
                            }

                            mostrarPopupDni = false
                            let accionPendiente = accionPendienteDni
                            accionPendienteDni = nil
                            dniIngresado = ""
                            accionPendiente?()
                        }
                    }
                )
            }

            if mostrarDialogoComplementos, let itemPendiente = itemPendienteAgregar {
                let precioBase = itemPendiente.precio
                let precioTotal = precioBase + calcularPrecioExtraComplementos(
                    grupos: gruposComplementos,
                    selecciones: seleccionesComplementos,
                    procesosExtras: producto.procesosExtras
                )

                DialogoSeleccionComplementos(
                    nombreProducto: producto.nombre,
                    nombresSeleccionablesPorFila: nombresSeleccionablesComplementos,
                    grupos: gruposComplementos,
                    selecciones: seleccionesComplementos,
                    precioTotal: precioTotal,
                    personalizables: producto.personalizables,
                    opcionesPersonalizablesSeleccionadas: itemProductoViewModel.opcionesPersonalizablesSeleccionadas,
                    onSeleccionar: { idGrupo, indiceFila, indiceOpcion in
                        guard var seleccionActual = seleccionesComplementos[idGrupo], seleccionActual.indices.contains(indiceFila) else {
                            return
                        }
                        seleccionActual[indiceFila] = indiceOpcion
                        seleccionesComplementos[idGrupo] = seleccionActual
                    },
                    onDismiss: {
                        mostrarDialogoComplementos = false
                        itemPendienteAgregar = nil
                    },
                    onConfirmar: {
                        if !validarHorarioReducido() {
                            return
                        }

                        if !validarMenuActivoCategoria() {
                            return
                        }

                        guard let itemOriginal = itemPendienteAgregar else {
                            return
                        }

                        let resumenComplementos = construirResumenComplementos(
                            grupos: gruposComplementos,
                            selecciones: seleccionesComplementos,
                            nombresSeleccionablesPorFila: nombresSeleccionablesComplementos
                        )
                        let resumenPreciosComplementos = construirResumenPreciosComplementos(
                            grupos: gruposComplementos,
                            selecciones: seleccionesComplementos,
                            procesosExtras: producto.procesosExtras
                        )
                        let precioFinal = precioBase + calcularPrecioExtraComplementos(
                            grupos: gruposComplementos,
                            selecciones: seleccionesComplementos,
                            procesosExtras: producto.procesosExtras
                        )

                        var itemActualizado = itemOriginal
                        itemActualizado.precio = precioFinal
                        itemActualizado.precioUnitario = itemOriginal.precioUnitario
                        itemActualizado.complementos = resumenComplementos
                        itemActualizado.preciosComplementos = resumenPreciosComplementos

                        guard let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else {
                            return
                        }

                        if limpiarCarritoEnConfirmacion {
                            carritoViewModel.limpiarYAgregarItemProducto(
                                perfilUsuarioState: perfilUsuarioState,
                                itemProducto: itemActualizado,
                                comercio: comercio,
                                direccion: direccion
                            )
                        } else {
                            carritoViewModel.agregarItemProducto(
                                perfilUsuarioState: perfilUsuarioState,
                                itemProducto: itemActualizado,
                                direccion: direccion
                            )
                        }

                        mostrarDialogoComplementos = false
                        itemPendienteAgregar = nil
                        onClose()
                    }
                )
            }
        }
        .overlay(ToastView(mensaje: $mensajeToast))
        .alert("Producto fuera de horario", isPresented: $mostrarDialogoHorarioReducido) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(mensajeDialogoHorarioReducido)
        }
        .alert("Producto no disponible", isPresented: $mostrarDialogoMenuNoDisponible) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(mensajeDialogoMenuNoDisponible)
        }
    }
    
    // --- Lógica de Validación (Cálculo de 'enabled') ---
    
    private func calcularSiEstaHabilitado() -> Bool {
        guard let item = itemProductoViewModel.itemProducto else { return false }
        
        let precioValido = item.precio > 0 || item.esPremio
        
        // Si no hay seleccionables obligatorios, solo valida precio
        guard let min = producto.cantidadMinimaSeleccionables, min > 0 else {
            return precioValido
        }
        
        // Si no hay ningún seleccionable disponible (ej: menú del mediodía fuera de horario), deshabilitar
        let haySeleccionablesDisponibles = (categoria.seleccionables ?? []).contains { $0.disponible }
        if !haySeleccionablesDisponibles {
            return false
        }
        
        let totalUnitarios = itemProductoViewModel.seleccionadosUnitarios.values.count { $0 == true }
        let totalMultiples = itemProductoViewModel.seleccionadosMultiples.values.reduce(0, +)
        
        // Nota: si cantidadMaximaSeleccionables es nil, la condición de múltiples es false (igual que Android)
        let seleccionValida = totalUnitarios >= min ||
                              (producto.cantidadMaximaSeleccionables != nil && totalMultiples == producto.cantidadMaximaSeleccionables!)
        
        return precioValido && seleccionValida
    }
    
    // --- Métodos de Acción ---
    
    private func agregarItemProducto(
        onClose: () -> Void
    ) {
        if(itemProductoViewModel.itemProducto == nil) { return }
        
        guard !perfilUsuarioState.esInvitado else {
            mostrarLoginRequerido = true
            return
        }

        if !validarHorarioReducido() {
            return
        }

        if !validarMenuActivoCategoria() {
            return
        }
        
        let direccion = perfilUsuarioState.obtenerUsuarioDireccion()
        let ciudad = perfilUsuarioState.ciudadSeleccionada
        
        if direccion != nil && ciudad != nil && !ciudad!.isEmpty {
            if carritoViewModel.validacionComercio(comercio: comercio) {
                ejecutarConValidacionDni {
                    let mostrarDialogo = prepararDialogoComplementos(
                        item: itemProductoViewModel.itemProducto!,
                        limpiarCarrito: false
                    )
                    if !mostrarDialogo {
                        carritoViewModel.agregarItemProducto(
                            perfilUsuarioState: perfilUsuarioState,
                            itemProducto: itemProductoViewModel.itemProducto!,
                            direccion: direccion!
                        )
                        onClose()
                    }
                }
            } else {
                mostrarDialogoConflicto = true
            }
        } else {
            mensajeToast = "Es necesario una dirección válida"
        }
    }
    
    private func limpiarYAgregarItemProducto(
        onClose: () -> Void
    ) {
        guard !perfilUsuarioState.esInvitado else {
            mostrarLoginRequerido = true
            return
        }
        if(itemProductoViewModel.itemProducto == nil
           || perfilUsuarioState.obtenerUsuarioDireccion() == nil) { return }

        if !validarHorarioReducido() {
            return
        }

        if !validarMenuActivoCategoria() {
            return
        }

        mostrarDialogoConflicto = false

        ejecutarConValidacionDni {
            let mostrarDialogo = prepararDialogoComplementos(
                item: itemProductoViewModel.itemProducto!,
                limpiarCarrito: true
            )
            if !mostrarDialogo {
                carritoViewModel.limpiarYAgregarItemProducto(
                    perfilUsuarioState: perfilUsuarioState,
                    itemProducto: itemProductoViewModel.itemProducto!,
                    comercio: comercio,
                    direccion: perfilUsuarioState.obtenerUsuarioDireccion()!
                )
                onClose()
            }
        }
    }

    private func prepararDialogoComplementos(item: ItemProducto, limpiarCarrito: Bool) -> Bool {
        let grupos = construirGruposComplementos(producto: producto, comercio: comercio)
        if grupos.isEmpty {
            return false
        }

        let tieneSeleccionables = (producto.cantidadMinimaSeleccionables ?? 0) > 0 && categoria.seleccionables != nil
        let cantidadSeleccionablesUnitarios = itemProductoViewModel.seleccionadosUnitarios.values.filter { $0 }.count
        let cantidadSeleccionablesMultiples = itemProductoViewModel.seleccionadosMultiples.values.reduce(0, +)

        let cantidadFilasComplementos: Int
        if tieneSeleccionables {
            cantidadFilasComplementos = max(
                cantidadSeleccionablesUnitarios,
                max(
                    cantidadSeleccionablesMultiples,
                    producto.cantidadMinimaSeleccionables ?? 1
                )
            )
        } else {
            cantidadFilasComplementos = item.cantidad
        }

        gruposComplementos = grupos
        seleccionesComplementos = Dictionary(uniqueKeysWithValues: grupos.map { grupo in
            let filas = grupo.porProducto == true ? 1 : cantidadFilasComplementos
            return (grupo.idInterno, Array(repeating: 0, count: filas))
        })

        let nombresSeleccionables = item.seleccionables.flatMap { seleccionable in
            Array(repeating: seleccionable.nombreSeleccionable, count: seleccionable.cantidad ?? 1)
        }

        if !nombresSeleccionables.isEmpty {
            if nombresSeleccionables.count >= cantidadFilasComplementos {
                nombresSeleccionablesComplementos = Array(nombresSeleccionables.prefix(cantidadFilasComplementos))
            } else {
                nombresSeleccionablesComplementos = nombresSeleccionables + Array(repeating: producto.nombre, count: cantidadFilasComplementos - nombresSeleccionables.count)
            }
        } else {
            nombresSeleccionablesComplementos = Array(repeating: producto.nombre, count: cantidadFilasComplementos)
        }

        itemPendienteAgregar = item
        limpiarCarritoEnConfirmacion = limpiarCarrito
        mostrarDialogoComplementos = true
        return true
    }

    private func validarHorarioReducido() -> Bool {
        let estaDisponible = DateUtils.productoDisponibleEnHorarioReducido(producto: producto, comercio: comercio)
        if estaDisponible {
            return true
        }

        let descripciones = DateUtils.obtenerDescripcionesHorariosReducidosProducto(producto: producto, comercio: comercio)
        let descripcionTexto = descripciones.isEmpty
            ? "el horario definido del producto"
            : descripciones.joined(separator: " / ")

        mensajeDialogoHorarioReducido = "Este producto solo está disponible en \(descripcionTexto)."
        mostrarDialogoHorarioReducido = true
        return false
    }

    private func validarMenuActivoCategoria() -> Bool {
        let menuActivo = comercio.menuActivo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let menuOpcionCategoria = categoria.menuOpcion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let comercioConMenus = !comercio.menuOpciones.isEmpty && !menuActivo.isEmpty
        if !comercioConMenus || menuOpcionCategoria.isEmpty {
            return true
        }

        if menuOpcionCategoria.caseInsensitiveCompare(menuActivo) == .orderedSame {
            return true
        }

        mensajeDialogoMenuNoDisponible = comercio.menuOpciones
            .first { opcion in
                opcion.idInterno.caseInsensitiveCompare(menuOpcionCategoria) == .orderedSame
            }?
            .mensajeError
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if mensajeDialogoMenuNoDisponible.isEmpty {
            mensajeDialogoMenuNoDisponible = "Este producto no está disponible en el menú activo de hoy."
        }

        mostrarDialogoMenuNoDisponible = true
        return false
    }

    private func requierePopupDni() -> Bool {
        let esComercioGrido = comercio.nombre
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .hasPrefix("grido")

        let dniActual = perfilUsuarioState.usuario?.datosPersonales?.dni
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let carritoEsDeEsteComercio = carritoViewModel.comercio?.idInterno == comercio.idInterno
        let hayItemsEnCarrito = !carritoViewModel.itemsProductos.isEmpty || !carritoViewModel.itemsPromociones.isEmpty
        let yaHayItemsDeEsteComercio = carritoEsDeEsteComercio && hayItemsEnCarrito

        return esComercioGrido && dniActual.isEmpty && !yaHayItemsDeEsteComercio
    }

    private func ejecutarConValidacionDni(onContinuar: @escaping () -> Void) {
        if !requierePopupDni() {
            onContinuar()
            return
        }

        accionPendienteDni = onContinuar
        mostrarPopupDni = true
    }
}

private struct PopupDniGridoView: View {
    let nombreComercio: String
    @Binding var dni: String
    let guardando: Bool
    let onNoGracias: () -> Void
    let onConfirmar: () -> Void

    private var dniValido: Bool {
        dni.count >= 4
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Sistema de Puntos")
                    .font(.custom("Barlow", size: 20))
                    .bold()
                    .foregroundColor(.negro)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("¿Quisieras indicarnos tu DNI para que \(nombreComercio) te sume los puntos de tu pedido?")
                    .font(.custom("Barlow", size: 16))
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)

                TextField("DNI", text: Binding(
                    get: { dni },
                    set: { nuevoValor in
                        dni = nuevoValor.filter { $0.isNumber }
                    }
                ))
                .keyboardType(.numberPad)
                .font(.custom("Barlow", size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )

                HStack(spacing: 12) {
                    Button(action: onNoGracias) {
                        Text("No Gracias")
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(.negro)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }

                    Button(action: onConfirmar) {
                        Text(guardando ? "Guardando..." : "Confirmar")
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(.blanco)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background((dniValido && !guardando) ? Color.verdePrincipal : Color.grisSecundario)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!dniValido || guardando)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background(Color.blanco)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct PortadaProducto: View {
    let producto: Producto
    let productoAlternativa: ProductoAlternativa?
    
    var body: some View {
        let altoDeseado = UIScreen.main.bounds.height * (1/3)
        
        ZStack(alignment: .topTrailing) {
            RemoteImage(
                url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? "")),
                fallbackURL: URL(string: API.baseURL + "/" + imagenPorDefectoURL(producto.imagenURL))
            )
            .frame(maxWidth: .infinity)
            .frame(height: altoDeseado)
            .clipped()
            .clipShape(
                RoundedCorners(radius: 32, corners: [.bottomLeft, .bottomRight])
            )
            
            if let descuento = producto.descuento, descuento > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RectanguloDescuento(
                            descuento: descuento,
                            fontSizeDescuento: 18,
                            redondeado: 18
                        )
                        .padding(12)
                    }
                }
            }
            
            // Rectángulo de descuento para productos con alternativas
            if productoAlternativa != nil &&
                productoAlternativa!.descuento != nil &&
                (productoAlternativa!.descuento)! > 0
            {
                VStack {
                    Spacer()
                    RectanguloDescuento(
                        descuento: productoAlternativa!.descuento!,
                        fontSizeDescuento: 18,
                        redondeado: 18
                    )
                    .padding(12)
                }
            }
        }
        .frame(height: altoDeseado)
    }
}
