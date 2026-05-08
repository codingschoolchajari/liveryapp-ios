//
//  PlacesSearchBar.swift
//  livery
//
//  Created by Nicolas Matias Garay on 06/01/2026.
//
import SwiftUI
import GooglePlaces

struct PlacesSearchBar: View {
    @State private var searchText = ""
    @StateObject private var autocompleteManager = PlaceAutocompleteManager()
    var coordenadasInicialesGPS: CLLocationCoordinate2D?
    var soloDirecciones: Bool = true
    var placeholder: String = "Buscar dirección"
    var onPlaceSelected: (GMSPlace) -> Void

    @State private var searchBarHeight: CGFloat = 44

    var body: some View {
        // CAMPO DE TEXTO (Buscador)
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.grisSecundario)

            TextField(
                text: $searchText,
                prompt: Text(placeholder)
                    .foregroundColor(.grisSecundario)
                    .font(.custom("Barlow", size: 16))
            ) {
                Text(placeholder)
            }
            .tint(.verdePrincipal)
            .autocapitalization(.words)
            .disableAutocorrection(true)
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            .background(Color.blanco)
            .onChange(of: searchText) { oldValue, newValue in
                print("🔍 [PlacesSearchBar] onChange — '\(oldValue)' → '\(newValue)'")
                autocompleteManager.buscarLugares(
                    text: newValue,
                    cercaDe: coordenadasInicialesGPS,
                    soloDirecciones: soloDirecciones
                )
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    autocompleteManager.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.grisSecundario)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.blanco)
        .foregroundColor(Color.negro)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.verdePrincipal, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // Medir altura del campo para posicionar el dropdown debajo
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { searchBarHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, h in searchBarHeight = h }
            }
        )
        // Dropdown como overlay flotante: no afecta el flujo del layout
        // y aparece sobre los campos del formulario gracias al zIndex del padre
        .overlay(alignment: .topLeading) {
            if !autocompleteManager.results.isEmpty {
                dropdownResultsView
                    .offset(y: searchBarHeight)
            }
        }
    }

    private var dropdownResultsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(autocompleteManager.results, id: \.placeID) { prediction in
                Button {
                    seleccionarLugar(id: prediction.placeID)
                } label: {
                    Text(prediction.attributedFullText.string)
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(Color.negro)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.blanco)

                if prediction.placeID != autocompleteManager.results.last?.placeID {
                    Divider().padding(.horizontal, 8)
                }
            }
        }
        .background(Color.blanco)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal, 10)
        .frame(maxHeight: 250)
    }

    // Función para obtener el GMSPlace detallado desde el ID
    private func seleccionarLugar(id: String) {
        let fields: GMSPlaceField = [.name, .coordinate, .addressComponents, .formattedAddress]
        
        GMSPlacesClient.shared().fetchPlace(fromPlaceID: id, placeFields: fields, sessionToken: nil) { (place, error) in
            if let error = error {
                print("Error al obtener lugar: \(error.localizedDescription)")
                return
            }
            if let place = place {
                // Cerramos la lista y limpiamos
                searchText = ""
                autocompleteManager.results = []
                
                // Ejecutamos tu callback original
                onPlaceSelected(place)
            }
        }
    }
}
