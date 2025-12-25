//
//  IntentDonationManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents
import Intents

enum HabitDonation {
    static func donate(intent: AppIntent) {
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate(completion: nil)
    }
}

