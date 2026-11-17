//
//  InflightRequests.swift
//  MyApp
//
//  Created by Manveer Singh on 15/11/26.
//

import Foundation
import UIKit

struct InflightRequests {
    var task: Task<UIImage, Error>
    var consumers: Set<UUID> {
        didSet {
            if consumers.isEmpty {
                task.cancel()
            }
        }
    }
}
