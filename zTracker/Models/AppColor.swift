//
//  Colors.swift
//  zTracker
//
//  Created by Jia Sahar on 12/16/25.
//

import Foundation
import SwiftData
import SwiftUI

enum AppColor: String, CaseIterable {
    case red
    case orange
    case yellow
    case theme
    case green
    case mint
    case teal
    case cyan
    case blue
    case indigo
    case purple
    case pink
    case brown
    case gray
}
extension AppColor {
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .theme: return .theme
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}


struct ColorExtractor {
    static func from(_ style: any ShapeStyle, in env: EnvironmentValues, fallback: Color = .primary) -> Color {
  
        let resolved = style.resolve(in: env)
        
        if let color = resolved as? Color {
            return color
        } else {
            return fallback
        }
    }
}

struct AppLinearGradient: View {
    @Environment(\.self) private var env
    @Environment(\.colorScheme) var colorScheme
    
    let selectedColor: Color
    
    var body: some View {
        
        let deviceColor: Color = colorScheme == .dark ? .black : .white
                
        return LinearGradient(
            colors: [deviceColor, selectedColor],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}


struct MovingLinearGradient: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animate = false
    
    let selectedColor: Color
    
    var body: some View {
        let deviceColor: Color = colorScheme == .dark ? .black : .white

        Rectangle()
            .fill(
                .ellipticalGradient(
                    colors: [selectedColor, deviceColor],
                    center: animate ? .leading : .bottomTrailing,
                    startRadiusFraction: 0.1,
                    endRadiusFraction: 1.0
                )
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 30)) {
                    animate.toggle()
                }
            }
    }
}

    


#Preview("MovingLinearGradient") {
    MovingLinearGradient(selectedColor: .theme)
}

#Preview("AppLinearGradient") {
    AppLinearGradient(selectedColor: .theme)
}
