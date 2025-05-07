//
//  TestView.swift
//  sp1
//
//  Created by 田中志門 on 5/7/25.
//

import Foundation

import SwiftUI

struct TestSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var sessionNumber: Int
    var pageRange: String
}

struct WeeklyTest: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var weekday: String
    var totalSessions: Int
    var sessions: [TestSession]
}

struct TestView: View {
    @AppStorage("weeklyTests") private var weeklyTestsData: Data = Data()
    @State private var weeklyTests: [WeeklyTest] = []

    @State private var newName = ""
    @State private var newWeekday = "月曜日"
    @State private var newTotalSessions = 1
    @State private var newSessionRanges: [String] = [""]

    let weekdays = ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"]

    var body: some View {
        NavigationView {
            VStack {
                List {
                    if weeklyTests.isEmpty {
                        Section {
                            Text("小テストが未登録です")
                                .foregroundColor(.gray)
                        }
                    } else {
                        ForEach(weeklyTests) { test in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(test.weekday) - \(test.name)")
                                    .font(.headline)
                                ForEach(test.sessions) { session in
                                    Text("第\(session.sessionNumber)回: \(session.pageRange)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteTest)
                    }
                }
            }
            .navigationTitle("小テスト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingSheet) {
                NavigationView {
                    Form {
                        TextField("小テスト名（例: 漢字）", text: $newName)

                        Picker("曜日", selection: $newWeekday) {
                            ForEach(weekdays, id: \.self) { day in
                                Text(day)
                            }
                        }

                        Stepper(value: $newTotalSessions, in: 1...10, step: 1) {
                            Text("回数: \(newTotalSessions) 回")
                        }
                        .onChange(of: newTotalSessions) { newCount in
                            if newCount > newSessionRanges.count {
                                newSessionRanges.append(contentsOf: Array(repeating: "", count: newCount - newSessionRanges.count))
                            } else if newCount < newSessionRanges.count {
                                newSessionRanges = Array(newSessionRanges.prefix(newCount))
                            }
                        }

                        ForEach(0..<newTotalSessions, id: \.self) { i in
                            TextField("第\(i + 1)回の範囲", text: $newSessionRanges[i])
                        }
                    }
                    .navigationTitle("小テストを追加")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("追加") {
                                let sessions = newSessionRanges.enumerated().map { index, range in
                                    TestSession(sessionNumber: index + 1, pageRange: range)
                                }
                                let newTest = WeeklyTest(name: newName, weekday: newWeekday, totalSessions: newTotalSessions, sessions: sessions)
                                weeklyTests.append(newTest)
                                save()
                                resetForm()
                                isPresentingSheet = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") {
                                isPresentingSheet = false
                            }
                        }
                    }
                }
            }
            .onAppear(perform: load)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(weeklyTests) {
            weeklyTestsData = encoded
        }
    }

    private func load() {
        if let decoded = try? JSONDecoder().decode([WeeklyTest].self, from: weeklyTestsData) {
            weeklyTests = decoded
        }
    }

    private func deleteTest(at offsets: IndexSet) {
        weeklyTests.remove(atOffsets: offsets)
        save()
    }

    private func resetForm() {
        newName = ""
        newWeekday = "月曜日"
        newTotalSessions = 1
        newSessionRanges = [""]
    }

    @State private var isPresentingSheet = false
}
