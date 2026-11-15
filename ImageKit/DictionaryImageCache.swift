//
//  DictionaryImageCache.swift
//  MyApp
//
//  Created by Manveer Singh on 15/11/26.
//

import Foundation

actor DictionaryImageCache {
    
    private var queue = DispatchQueue(label: "com.imagekit.dictionary-image-cache-concurrent-queue", qos: .userInteractive, attributes: .concurrent)
    
    private var dictionary: [URL : Data] = [:]
    
    func store(data: Data, for url: URL) throws {
        queue.sync(flags: .barrier) {
            dictionary[url] = data
        }
    }
    
    func get(for url: URL) async throws -> Data? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let data = self.dictionary[url]
                continuation.resume(returning: data)
            }
            
        }
    }
    
    func remove(for url: URL) throws {
        queue.sync(flags: .barrier) {
            dictionary[url] = nil
        }
    }
    
    func clearCache() throws {
        queue.sync(flags: .barrier) {
            dictionary = [:]
        }
    }
}
