//
//  TodayView.swift
//  sp1
//
//  Created by 田中志門 on 5/1/25.
//


import Foundation
import SwiftUI

struct TodayView: View {
    @AppStorage("timetable") private var timetableData: Data = Data()
    @AppStorage("periods") private var periodsData: Data = Data()
    @AppStorage("assignments") private var assignmentsData: Data = Data()
    @AppStorage("weeklyTests") private var weeklyTestsData: Data = Data()
    
    @State private var selectedAssignment: Assignment? = nil
    
    private var timetable: [[SubjectEntry?]] {
        (try? JSONDecoder().decode([[SubjectEntry?]].self, from: timetableData)) ?? Array(repeating: Array(repeating: nil, count: days.count), count: 6)
    }
    
    private var periods: [ClassPeriod] {
        (try? JSONDecoder().decode([ClassPeriod].self, from: periodsData)) ?? []
    }
    
    private var todaySchedule: [SubjectEntry] {
        let weekday = Calendar.current.component(.weekday, from: Date())
        guard weekday >= 2 && weekday <= 7 else { return [] }
        let column = weekday - 2
        let now = Date()
        return timetable.enumerated().compactMap { (index, row) in
            guard let subject = row[column], index < periods.count else { return nil }
            let period = periods[index]
            return period.end > now ? subject : nil
        }
    }
    
    private var importantTasks: [Assignment] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let oneWeekLater = calendar.date(byAdding: .day, value: 7, to: now)!
        let tasks = (try? JSONDecoder().decode([Assignment].self, from: assignmentsData
                                              )) ?? []
        return tasks.filter {
            $0.isStarred || (calendar.startOfDay(for: $0.deadline) >= now && calendar.startOfDay(for: $0.deadline) <= oneWeekLater)
        }.sorted { $0.deadline < $1.deadline }
    }
    
    private var weeklyTests: [WeeklyTest] {
        let tests = (try? JSONDecoder().decode([WeeklyTest].self, from: weeklyTestsData)) ?? []
        let today = Date()
        return tests.compactMap { test in
            guard let nextSession = test.sessions.first(where: { $0.date >= today }) else { return nil }
            var nextTest = test
            nextTest.sessions = [nextSession]
            return nextTest
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("今日の時間割")) {
                    if todaySchedule.isEmpty {
                        Text(Calendar.current.component(.weekday, from: Date()) == 1 ? "今日は日曜日です" : "今日の授業はありません")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(todaySchedule.indices, id: \.self) { index in
                            let lesson = todaySchedule[index]
                            VStack(alignment: .leading) {
                                Text(lesson.subject)
                                    .font(.headline)
                                Text(lesson.teacher)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                Section(header: Text("重要な課題")) {
                    if importantTasks.isEmpty {
                        Text("重要な課題はありません")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(importantTasks) { task in
                            let deadlineDay = Calendar.current.startOfDay(for: task.deadline)
                            let today = Calendar.current.startOfDay(for: Date())
                            let isOverdue = deadlineDay < today
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(task.title)
                                        if task.isStarred {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    Text("締切: \(formattedDate(task.deadline))")
                                        .font(.caption)
                                        .foregroundColor(isOverdue ? .red : .gray)
                                }
                                Spacer()
                                Button(action: {
                                    selectedAssignment = task
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }
                Section(header: Text("小テスト")) {
                    if weeklyTests.isEmpty {
                        Text("小テストはありません")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(weeklyTests) { test in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.name)
                                    .font(.headline)
                                ForEach(test.sessions) { session in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("第\(session.sessionNumber)回")
                                            .font(.subheadline)
                                        Text("日付: \(formattedDate(session.date))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("範囲: \(session.pageRange)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("ホーム")
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(item: $selectedAssignment) { assignment in
                TaskDetailSheet(
                    assignment: assignment,
                    onSave: { _ in selectedAssignment = nil },
                    onDelete: { selectedAssignment = nil }
                )
            }
        }
    }
}
