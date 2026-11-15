//
//  MemoryImageCache.swift
//  MyApp
//
//  Created by Manveer Singh on 12/11/26.
//

import Foundation

final class MemoryImageCache: ImageDataCache {
    let cache: NSCache<NSURL, NSData>
    
    init(cache: NSCache<NSURL, NSData>) {
        self.cache = cache
    }
    
    func store(data: Data, for url: URL) {
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
    }
    
    func get(for url: URL) -> Data? {
        return cache.object(forKey: url as NSURL) as? Data
    }
    
    func remove(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
