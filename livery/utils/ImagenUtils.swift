//
//  ImagenUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import UIKit
import AVFoundation
import PDFKit

func redimensionarImagen(
    imageBytes: Data,
    maxWidth: CGFloat,
    maxHeight: CGFloat,
    quality: CGFloat = 0.9
) -> Data? {
    // 1. Decodificar Data a UIImage (Equivalente a decodeByteArray)
    guard let originalImage = UIImage(data: imageBytes) else { return nil }

    let originalSize = originalImage.size
    
    // 2. Calcular la escala manteniendo la proporción (Equivalente a ratio)
    let widthRatio  = maxWidth  / originalSize.width
    let heightRatio = maxHeight / originalSize.height
    
    // Usamos el mínimo para asegurar que quepa en ambos límites
    let ratio = min(widthRatio, heightRatio)
    
    // Solo redimensionamos si la imagen es más grande que los límites
    let newSize = CGSize(
        width: originalSize.width * ratio,
        height: originalSize.height * ratio
    )

    // 3. Redimensionar usando un contexto de dibujo
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    originalImage.draw(in: CGRect(origin: .zero, size: newSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    // 4. Convertir de nuevo a Data (Equivalente a compress)
    // Usamos jpegData para comprimir con calidad, o pngData() si necesitas transparencia
    return scaledImage?.jpegData(compressionQuality: quality)
}

func convertirPdfAJpg(pdfData: Data) -> Data? {
    // 1. Crear el documento PDF a partir de los bytes
    guard let provider = CGDataProvider(data: pdfData as CFData),
          let pdfDoc = CGPDFDocument(provider),
          let page = pdfDoc.page(at: 1) else { return nil }

    // 2. Obtener el tamaño de la página (MediaBox)
    let pageRect = page.getBoxRect(.mediaBox)
    
    // 3. Crear un renderizador de imagen
    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
    
    let img = renderer.image { ctx in
        UIColor.white.set() // Fondo blanco (importante si el PDF es transparente)
        ctx.fill(pageRect)
        
        ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
        
        ctx.cgContext.drawPDFPage(page)
    }
    
    // 4. Retornar como JPEG (usando tu calidad estándar de 0.9)
    return img.jpegData(compressionQuality: 0.9)
}
