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

actor DefaultImageRepository: ImageRepository {
    private let diskImageCache: ImageDataCache?
    private let memoryImageCache: ImageDataCache
    private let imageDownloader: ImageDownloader
    private let imageProcessor: ImageProcessor
    private var inFlightRequests: [URL: InflightRequests] = [:]
    
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
    
    func loadImage(with url: URL, consumerId: UUID) async throws -> UIImage {
        try Task.checkCancellation()
        
        
        if let image = await loadImageFromMemoryCache(with: url) {
            try Task.checkCancellation()
            
            return image
        }
        
        if let imageDataDisk = try? await diskImageCache?.get(for: url),
           let image = try? await imageProcessor.process(imageDataDisk) {
            try? await memoryImageCache.store(data: imageDataDisk, for: url)
            
            try Task.checkCancellation()
            
            return image
        }
        
        try Task.checkCancellation()
        
        if let existingTask = inFlightRequests[url] {
            inFlightRequests[url]?.consumers.insert(consumerId)
            
            defer {
                removeConsumer(for: url, consumerId: consumerId)
            }
            
            let image = try await existingTask.task.value
            
            try Task.checkCancellation()
            
            return image
        }
        
        if let image = await loadImageFromMemoryCache(with: url) {
            try Task.checkCancellation()
            
            return image
        }
        
        let newTask = Task {
            let remoteImageData = try await imageDownloader.download(with: url)
            try? await memoryImageCache.store(data: remoteImageData, for: url)
            try? await diskImageCache?.store(data: remoteImageData, for: url)
            return try await imageProcessor.process(remoteImageData)
        }
        
        var consumerIds = Set<UUID>()
        consumerIds.insert(consumerId)
        inFlightRequests[url] = InflightRequests(task: newTask, consumers: consumerIds)
        
        do {
            defer {
                removeConsumer(for: url, consumerId: consumerId)
            }
            
            let image = try await newTask.value
            
            try Task.checkCancellation()
            
            return image
        }
    }
    
    func loadImage(with url: URL) async throws -> UIImage {
        let consumerId = UUID()
        
        return try await withTaskCancellationHandler {
            return try await self.loadImage(with: url, consumerId: consumerId)
        } onCancel: {
            Task {
                await self.handleCancellation(for: url, consumerId: consumerId)
            }
        }

    }
    
    private func loadImageFromMemoryCache(with url: URL) async -> UIImage? {
        if let imagedata = try? await memoryImageCache.get(for: url),
           let image = try? await imageProcessor.process(imagedata) {
            return image
        }
        
        return nil
    }
    
    private func removeConsumer(for url: URL, consumerId: UUID, isCancelled: Bool = false) {
        inFlightRequests[url]?.consumers.remove(consumerId)
        
        if inFlightRequests[url]?.consumers.isEmpty ?? false {
            if isCancelled {
                inFlightRequests[url]?.task.cancel()
            }

            inFlightRequests[url] = nil
        }
    }
    
    private func handleCancellation(for url: URL, consumerId: UUID) {
        removeConsumer(for: url, consumerId: consumerId, isCancelled: true)
    }
}
