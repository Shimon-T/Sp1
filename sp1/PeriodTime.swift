//
//  PeriodTime.swift
//  sp1
//
//  Created by 田中志門 on 5/1/25.
//


import Foundation

struct ClassPeriod: Identifiable, Codable, Equatable {
    var id = UUID()
    var start: Date
    var end: Date
}
