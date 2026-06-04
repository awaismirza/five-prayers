//
//  Item.swift
//  Salah Logbook
//
//  Created by mohr on 5/6/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
