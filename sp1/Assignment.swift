//
//  Assignment.swift
//  sp1
//
//  Created by 田中志門 on 5/1/25.
//

import Foundation

struct Assignment: Identifiable, Codable, Equatable {
    var id = UUID()
    var subject: String
    var title: String
    var deadline: Date
    var isStarred: Bool
    var submissionMethod: String
}
