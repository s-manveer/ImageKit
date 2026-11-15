//
//  ImageRepository.swift
//  MyApp
//
//  Created by Manveer Singh on 12/11/26.
//

import Foundation
import SwiftUI

protocol ImageRepository {
    func loadImage(with url: URL) async throws -> UIImage
}

class DefaultImageRepository: ImageRepository {
    private let diskImageCache: ImageDataCache?
    private let memoryImageCache: ImageDataCache
    private let imageDownloader: ImageDownloader
    private let imageProcessor: ImageProcessor
    private var inFlightRequests: [URL: InflightRequests] = [:]
    
    private let serialQueue = DispatchQueue(label: "com.imagekit.repository.state")
    
    init(
        imageDownloader: ImageDownloader,
        diskImageCache: ImageDataCache?,
        memoryImageCache: ImageDataCache,
        imageProcessor: ImageProcessor
    ) {
        self.diskImageCache = diskImageCache
        self.imageDownloader = imageDownloader
        self.memoryImageCache = memoryImageCache
        self.imageProcessor = imageProcessor
    }
    
    func loadImage(with url: URL) async throws -> UIImage {
        if let imagedata = try? memoryImageCache.get(for: url),
           let image = try? imageProcessor.process(imagedata) {
            return image
        }
        
        if let imageDataDisk = try? diskImageCache?.get(for: url),
           let image = try? imageProcessor.process(imageDataDisk) {
            try? memoryImageCache.store(data: imageDataDisk, for: url)
            return image
        }
        
        let thisTask = serialQueue.sync {
            if let existingTask = inFlightRequests[url] {
                return existingTask
            }
            
            let newTask = Task {
                let remoteImageData = try await imageDownloader.download(with: url)
                try? memoryImageCache.store(data: remoteImageData, for: url)
                try? diskImageCache?.store(data: remoteImageData, for: url)
                return try imageProcessor.process(remoteImageData)
            }
            
            let inflightTask = InflightRequests(task: newTask)
            
            inFlightRequests[url] = inflightTask
            return inflightTask
        }
        
        do {
            let image = try await thisTask.task.value
            
            serialQueue.sync {
                if inFlightRequests[url]?.id == thisTask.id {
                    inFlightRequests[url] = nil
                }
            }
            
            return image
        } catch {
            serialQueue.sync {
                if inFlightRequests[url]?.id == thisTask.id {
                    inFlightRequests[url] = nil
                }
            }
            
            throw error
        }
    }
}
