//
//  ImageDownloader.swift
//  MyApp
//
//  Created by Manveer Singh on 12/11/26.
//

import Foundation

protocol ImageDownloader: Sendable {
    func download(with url: URL) async throws -> Data
}

protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession { }

final class URLSessionImageDownloader: ImageDownloader {
    
    private enum ImageDownloaderError: Error {
        case invalidResponse
        case httpError(statusCode: Int)
    }
 
    let session: NetworkSession
    
    init(session: NetworkSession) {
        self.session = session
    }
    
    func download(with url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        
        let (data, urlResponse) = try await session.data(for: request)
        
        guard let response = urlResponse as? HTTPURLResponse else {
            throw ImageDownloaderError.invalidResponse
        }
        
        let statusCode = response.statusCode
        
        guard (200...299).contains(statusCode) else  {
            throw ImageDownloaderError.httpError(statusCode: statusCode)
        }
        
        return data
    }
}
