//
//  CircularProgressView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import SwiftData

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke()
                .glassEffect()
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke()
                .rotationEffect(.degrees(-90))
                .glassEffect()
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
