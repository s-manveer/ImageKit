//
//  ImageKit.swift
//  MyApp
//
//  Created by Manveer Singh on 10/11/26.
//

import Foundation
import UIKit
import CryptoKit

protocol ImageKit {
    func loadImage(with url: URL) async throws -> UIImage
}

final class DefaultImageKit: ImageKit {
    private let repository: ImageRepository
    
    static let shared = DefaultImageKit()
    
    private init() {
        let memoryImageCache = MemoryImageCache(cache: NSCache<NSURL, NSData>())
        let diskImageCache = try? DiskImageCache()
        let imageProcessor = DefaultImageProcessor()
        
        
        repository = DefaultImageRepository(
            imageDownloader: URLSessionImageDownloader(session: URLSession.shared),
            diskImageCache: diskImageCache,
            memoryImageCache: memoryImageCache,
            imageProcessor: imageProcessor
        )
    }
    
    func loadImage(with url: URL) async throws -> UIImage {
        return try await repository.loadImage(with: url)
    }
}
