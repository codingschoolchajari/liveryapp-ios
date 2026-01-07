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
    var onPlaceSelected: (GMSPlace) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // CAMPO DE TEXTO (Buscador)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.grisSecundario)
                
                TextField(
                    text: $searchText,
                    prompt: Text("Buscar dirección")
                        .foregroundColor(.grisSecundario)
                        .font(.custom("Barlow", size: 16))
                ) {
                    Text("Buscar dirección")
                }
                .tint(.verdePrincipal)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .background(Color.blanco)
                .onChange(of: searchText) { oldValue, newValue in
                    autocompleteManager.buscarLugares(
                        text: newValue,
                        cercaDe: coordenadasInicialesGPS
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
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blanco)
            .foregroundColor(Color.negro)
            .cornerRadius(20)
            .shadow(radius: 4)
            .zIndex(1)

            if !autocompleteManager.results.isEmpty {
                VStack {
                    List(autocompleteManager.results, id: \.placeID) { prediction in
                        Button {
                            seleccionarLugar(id: prediction.placeID)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(prediction.attributedFullText.string)
                                    .font(.custom("Barlow", size: 14))
                                    .foregroundColor(Color.negro)
                            }
                            .padding(.vertical, 4)
                            .background(Color.blanco)
                        }
                        .listRowBackground(Color.blanco)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: 250) // Altura máxima de la lista
                }
                .background(Color.blanco)
                .cornerRadius(10)
                .padding(.horizontal, 10)
                .shadow(radius: 2)
            }
        }
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
