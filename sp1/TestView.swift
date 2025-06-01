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
    var date: Date
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
    @State private var newSessionDates: [Date] = [Date()]

    @State private var editingTest: WeeklyTest?

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
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(test.name)
                                        .font(.headline)
                                    if let nextSession = test.sessions.first(where: { $0.date >= Date() }) {
                                        Text("次回（第\(nextSession.sessionNumber)回）: \(nextSession.pageRange)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    editingTest = test
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = weeklyTests.firstIndex(of: test) {
                                        weeklyTests.remove(at: index)
                                        save()
                                    }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
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
                        .onChange(of: newWeekday) { oldValue, newValue in
                            newSessionDates = generateDefaultDates(count: newTotalSessions)
                        }

                        Stepper(value: $newTotalSessions, in: 1...30, step: 1) {
                            Text("回数: \(newTotalSessions) 回")
                        }
                        .onChange(of: newTotalSessions) { oldValue, newCount in
                            if newCount > newSessionRanges.count {
                                newSessionRanges.append(contentsOf: Array(repeating: "", count: newCount - newSessionRanges.count))
                            } else {
                                newSessionRanges = Array(newSessionRanges.prefix(newCount))
                            }

                            if newSessionDates.isEmpty {
                                newSessionDates = generateDefaultDates(count: newCount)
                            } else {
                                var updatedDates: [Date] = []
                                let calendar = Calendar.current
                                updatedDates.append(newSessionDates[0])
                                var start = calendar.date(byAdding: .weekOfYear, value: 1, to: newSessionDates[0]) ?? newSessionDates[0]
                                for _ in 1..<newCount {
                                    updatedDates.append(start)
                                    start = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
                                }
                                newSessionDates = updatedDates
                            }
                        }

                        ForEach(0..<newTotalSessions, id: \.self) { i in
                            VStack(alignment: .leading) {
                                DatePicker("第\(i + 1)回 日付", selection: Binding(
                                    get: {
                                        if i < newSessionDates.count {
                                            return newSessionDates[i]
                                        } else {
                                            return Date()
                                        }
                                    },
                                    set: { newDate in
                                        if i < newSessionDates.count {
                                            newSessionDates[i] = newDate
                                        }
                                    }
                                ), displayedComponents: .date)
                                TextField("第\(i + 1)回の範囲", text: Binding(
                                    get: {
                                        if i < newSessionRanges.count {
                                            return newSessionRanges[i]
                                        } else {
                                            return ""
                                        }
                                    },
                                    set: { newValue in
                                        if i < newSessionRanges.count {
                                            newSessionRanges[i] = newValue
                                        }
                                    }
                                ))
                            }
                        }
                    }
                    .navigationTitle("小テストを追加")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("追加") {
                                let sessions = zip(newSessionRanges, newSessionDates).enumerated().map { index, pair in
                                    TestSession(sessionNumber: index + 1, pageRange: pair.0, date: pair.1)
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
                                resetForm()
                                isPresentingSheet = false
                            }
                        }
                    }
                }
            }
            .sheet(item: $editingTest) { test in
                TestDetailSheet(
                    test: test,
                    onSave: { updated in
                        if let index = weeklyTests.firstIndex(where: { $0.id == updated.id }) {
                            weeklyTests[index] = updated
                            save()
                        }
                        editingTest = nil
                    },
                    onDelete: {
                        if let index = weeklyTests.firstIndex(where: { $0.id == test.id }) {
                            weeklyTests.remove(at: index)
                            save()
                        }
                        editingTest = nil
                    }
                )
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
        newSessionDates = [Date()]
    }

    private func generateDefaultDates(count: Int) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let weekdaySymbols = ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
        guard let weekdayIndex = weekdaySymbols.firstIndex(of: newWeekday) else { return [] }

        let today = Date()
        var start = calendar.nextDate(after: today, matching: DateComponents(weekday: weekdayIndex + 1), matchingPolicy: .nextTime) ?? today

        for _ in 0..<count {
            dates.append(start)
            start = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
        }

        return dates
    }

    @State private var isPresentingSheet = false
}

struct TestDetailSheet: View {
    @State var test: WeeklyTest
    var onSave: (WeeklyTest) -> Void
    var onDelete: () -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(test.sessions.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("第\(test.sessions[index].sessionNumber)回")
                            .font(.headline)
                        DatePicker("日付", selection: Binding(
                            get: { test.sessions[index].date },
                            set: { test.sessions[index].date = $0 }),
                            displayedComponents: .date)
                        TextField("範囲", text: Binding(
                            get: { test.sessions[index].pageRange },
                            set: { test.sessions[index].pageRange = $0 }))
                    }
                }
                // Delete button section at the bottom
                Section {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Text("削除")
                    }
                }
            }
            .navigationTitle(test.name)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    onSave(test)
                },
                trailing: Button("保存") {
                    onSave(test)
                }
            )
            .listStyle(InsetGroupedListStyle())
            .listRowInsets(EdgeInsets())
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}
