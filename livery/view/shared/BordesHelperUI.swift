//
//  BordesHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 21/12/2025.
//
import SwiftUI

struct RoundedCorners: Shape {

    var radius: CGFloat = 16
    var corners: UIRectCorner = [.bottomLeft, .bottomRight]

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
