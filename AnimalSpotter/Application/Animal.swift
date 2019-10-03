//
//  Animal.swift
//  AnimalSpotter
//
//  Created by Jonalynn Masters on 10/3/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

struct Animal: Codable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let timeSeen: Date
    let description: String
    let imageURL: String
}
