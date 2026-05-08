//
//  Untitled.swift
//  livery
//
//  Created by Nicolas Matias Garay on 07/01/2026.
//
import Foundation
import GooglePlaces
import Combine

class PlaceAutocompleteManager: ObservableObject {

    @Published var results: [GMSAutocompletePrediction] = []

    private let client = GMSPlacesClient.shared()
    private let sessionToken = GMSAutocompleteSessionToken()

    func buscarLugares(
        text: String,
        cercaDe coordenadas: CLLocationCoordinate2D?,
        soloDirecciones: Bool = true
    ) {
        print("🔍 [Autocomplete] buscarLugares llamado — texto: '\(text)' (largo: \(text.count))")

        guard text.count >= 2 else {
            print("🔍 [Autocomplete] texto muy corto, limpiando resultados")
            results = []
            return
        }

        let filter = GMSAutocompleteFilter()
        if soloDirecciones {
            filter.types = ["address"]
            print("🔍 [Autocomplete] filtro: solo direcciones")
        } else {
            print("🔍 [Autocomplete] filtro: cualquier lugar")
        }
        filter.countries = ["AR"]

        if let coords = coordenadas {
            let norte = CLLocationCoordinate2D(latitude: coords.latitude + 0.15, longitude: coords.longitude + 0.15)
            let sur = CLLocationCoordinate2D(latitude: coords.latitude - 0.15, longitude: coords.longitude - 0.15)
            filter.locationRestriction = GMSPlaceRectangularLocationOption(norte, sur)
            print("🔍 [Autocomplete] restricción geográfica activa — centro: (\(coords.latitude), \(coords.longitude))")
        } else {
            print("🔍 [Autocomplete] sin restricción geográfica (coordenadas nil)")
        }

        print("🔍 [Autocomplete] llamando a findAutocompletePredictions...")

        client.findAutocompletePredictions(
            fromQuery: text,
            filter: filter,
            sessionToken: sessionToken
        ) { predictions, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    print("❌ [Autocomplete] error — dominio: \(nsError.domain) código: \(nsError.code) mensaje: \(nsError.localizedDescription)")
                    self.results = []
                    return
                }

                guard let predictions = predictions else {
                    print("⚠️ [Autocomplete] predictions es nil sin error — posible problema de API key o cuota")
                    self.results = []
                    return
                }

                print("✅ [Autocomplete] \(predictions.count) resultado(s) para '\(text)'")
                predictions.forEach { p in
                    print("   → \(p.attributedFullText.string) (placeID: \(p.placeID ?? "nil"))")
                }

                self.results = predictions
            }
        }
    }
}




