//
//  ImageDataCache.swift
//  MyApp
//
//  Created by Manveer Singh on 12/11/26.
//

import Foundation

protocol ImageDataCache {
    func store(data: Data, for url: URL) throws
    func get(for url: URL) throws -> Data?
    func remove(for url: URL) throws
    func clearCache() throws
}
