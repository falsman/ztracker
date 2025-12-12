//
//  Item.swift
//  ztracker
//
//  Created by Jia Sahar on 12/12/25.
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
