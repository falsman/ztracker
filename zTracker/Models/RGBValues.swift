//
//  Colors.swift
//  zTracker
//
//  Created by Jia Sahar on 12/16/25.
//

import Foundation
import SwiftData
import SwiftUI

struct RGBValues: Codable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double = 1.0
}

extension RGBValues {
    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
