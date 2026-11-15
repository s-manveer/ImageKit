//
//  InflightRequests.swift
//  MyApp
//
//  Created by Manveer Singh on 15/11/26.
//

import Foundation
import UIKit

struct InflightRequests: Identifiable {
    let id: UUID = UUID()
    var task: Task<UIImage, Error>
}
