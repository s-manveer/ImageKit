//
//  ImageProcessor.swift
//  MyApp
//
//  Created by Manveer Singh on 12/11/26.
//

import Foundation
import UIKit

protocol ImageProcessor {
    func process(_ data: Data) throws -> UIImage
}

final class DefaultImageProcessor: ImageProcessor {
    private enum ImageProcessorError: Error {
        case invalidImageData
    }

    func process(_ data: Data) throws -> UIImage {
        guard let image =  UIImage(data: data) else { throw ImageProcessorError.invalidImageData }
        
        return image
    }
}
