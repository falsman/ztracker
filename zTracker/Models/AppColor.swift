//
//  Colors.swift
//  zTracker
//
//  Created by Jia Sahar on 12/16/25.
//

import Foundation
import SwiftData
import SwiftUI

enum AppColorID: String, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case gray
    case theme
}
extension AppColorID {
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .gray: return .gray
        case .theme: return Color("themeColor")
        }
    }
}


struct linearGradient: View {
    let selectedColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        var deviceColor: Color
        
        if colorScheme == .dark { deviceColor = .black }
        else { deviceColor = .white }
        
        return LinearGradient(
            colors: [deviceColor, selectedColor],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
