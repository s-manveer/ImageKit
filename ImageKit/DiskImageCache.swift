//
//  DiskImageCache.swift
//  MyApp
//
//  Created by Manveer Singh on 12/11/26.
//

import Foundation
import CryptoKit

final class DiskImageCache: ImageDataCache {
    private let cacheDirectory: URL
    
    init() throws {
        let fileManager = FileManager.default
        
        let cacheDirectoryURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = cacheDirectoryURL.appendingPathComponent("ImageKit", isDirectory: true)
        
        cacheDirectory = directory
        
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    private func fileURL(url: URL) -> URL {
        let urlString = url.absoluteString
        let urlStringData = Data(urlString.utf8)
        let digest = SHA256.hash(data: urlStringData)
        let fileName = digest.map { String(format: "%02x", $0)}.joined()
        
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    func store(data: Data, for url: URL) throws {
        let destinationURL = fileURL(url: url)
        try data.write(to: destinationURL, options: .atomic)
    }
    
    func get(for url: URL) throws -> Data? {
        let destinationURL = fileURL(url: url)
        
        guard FileManager.default.fileExists(atPath: destinationURL.path()) else { return nil }
        
        return try Data(contentsOf: destinationURL)
        
    }
    
    func remove(for url: URL) throws {
        let fileURL = fileURL(url: url)
        
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return }
        
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func clearCache() throws {
        let fileManager = FileManager.default

            if fileManager.fileExists(atPath: cacheDirectory.path) {
                try fileManager.removeItem(at: cacheDirectory)
            }

            try fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
    }
}
