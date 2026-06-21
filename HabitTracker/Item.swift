//
//  Item.swift
//  HabitTracker
//
//  Created by Nam Le on 21/6/26.
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
