//
//  TextosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 27/12/2025.
//
import SwiftUI

struct Titulo: View {
    let titulo: String
    
    var body: some View {
        HStack {
            Spacer()
            
            Text(titulo)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
