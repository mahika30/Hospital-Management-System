//
//  Gender.swift
//  iHMS
//
//  Created by Hargun Singh on 05/01/26.
//

import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case other

    var id: String { rawValue }
}
