//
//  DescuentosView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct DescuentosView: View {
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject private var descuentosViewModel : DescuentosViewModel
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        _descuentosViewModel = StateObject(
            wrappedValue: DescuentosViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            VStack(spacing: 0) {
                Spacer().frame(height: 8)
                Titulo(titulo: "Descuentos")
                Spacer().frame(height: 8)
                
                if  ( perfilUsuarioState.ciudadSeleccionada != nil
                      && perfilUsuarioState.ciudadSeleccionada == StringUtils.sinCobertura
                    ) || (
                        perfilUsuarioState.usuario != nil
                        && perfilUsuarioState.usuario!.direcciones?.isEmpty ?? true
                    )
                {
                    DireccionFueraDeCobertura()
                } else {
                    Descuentos(
                        descuentosViewModel: descuentosViewModel
                    )
                }
            }
        }
        .sheet(item: $descuentosViewModel.productoSeleccionado) { productoSeleccionado in
            if(descuentosViewModel.categoria != nil &&
               descuentosViewModel.comercio != nil
            ){
                BottomSheetSeleccionProducto(
                    producto: productoSeleccionado,
                    categoria: descuentosViewModel.categoria!,
                    comercio: descuentosViewModel.comercio!,
                    onClose: {
                        descuentosViewModel.limpiarProductoSeleccionado()
                    }
                )
                .onDisappear {
                    descuentosViewModel.limpiarProductoSeleccionado()
                }
            }
        }
    }
}

struct Descuentos: View {
    @ObservedObject var descuentosViewModel: DescuentosViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(descuentosViewModel.comerciosDescuentos) { item in
                    FilaComercioDescuento(
                        comercioDescuentos: item,
                        descuentosViewModel: descuentosViewModel
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .refreshable {
            descuentosViewModel.inicio()
        }
    }
}

struct FilaComercioDescuento: View {
    let comercioDescuentos: ComercioDescuentos
    @ObservedObject var descuentosViewModel: DescuentosViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Construimos el objeto comercio aquí
            let comercio = Comercio(
                idInterno: comercioDescuentos.idComercio,
                nombre: comercioDescuentos.nombreComercio,
                logoURL: comercioDescuentos.logoComercioURL
            )
            
            TituloComercio(comercio: comercio)
            
            Spacer().frame(height: 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(comercioDescuentos.productos) { producto in
                        ProductoMiniatura(producto: producto) {
                            Task {
                                await descuentosViewModel.inicializarProductoSeleccionado(
                                    idComercio: comercio.idInterno,
                                    idProducto: producto.idInterno
                                )
                            }
                        }
                        .frame(height: 190)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(.grisSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer().frame(height: 4)
        }
    }
}

struct DescuentoSeleccionado: Identifiable {
    let id = UUID()
    let idComercio: String
    let producto: Producto
}
