//
//  InteractiveSnippetViews.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import SwiftUI

struct HabitCompletionSnippet: View {
    let habitTitle: String
    let completed: Bool
    
    var body: some View {
        VStack {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.largeTitle)
                .foregroundStyle(completed ? .green : .secondary)
            
            Text(habitTitle)
                .font(.headline)
            
            Text(completed ? "Completed" : "Not Completed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct HabitRatingSnippet: View {
    let habitTitle: String
    let rating: Int
    let maxRating: Int
    
    var body: some View {
        VStack {
            HStack {
                ForEach(1...maxRating, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                }
            }
            .font(.title2)
            
            Text(habitTitle)
                .font(.headline)
            
            Text("\(rating)/\(maxRating)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct HabitNumericSnippet: View {
    let habitTitle: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack {
            Text(String(format: "%.1f", value))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text(habitTitle)
                .font(.headline)
        }
        .padding()
    }
}

struct HabitDurationSnippet: View {
    let habitTitle: String
    let duration: Duration
    
    var body: some View {
        let hours = Int(duration.components.seconds) / 3600
        let minutes = (Int(duration.components.seconds) % 3600) / 60
        
        VStack {
            HStack {
                if hours > 0 {
                    Text("\(hours)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("h")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                if minutes > 0 || hours == 0 {
                    Text("\(minutes)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("m")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(habitTitle)
                .font(.headline)
        }
        .padding()
    }
}

#Preview {
    let timeDuration: Duration = .seconds(9000)
    HabitDurationSnippet(habitTitle: "Test", duration: timeDuration)
}

#Preview {
    HabitNumericSnippet(habitTitle: "Test", value: 45, unit: "gays")
}

#Preview {
    HabitRatingSnippet(habitTitle: "Test", rating: 3, maxRating: 10)
}

#Preview {
    HabitCompletionSnippet(habitTitle: "Test", completed: true)
}

