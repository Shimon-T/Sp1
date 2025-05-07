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
    @State private var isPresentingDetail = false
    
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
        return timetable.compactMap { $0[column] }
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
        let todayWeekday = Calendar.current.component(.weekday, from: Date()) // 1: Sunday, 2: Monday, ...
        let japaneseWeekdays = ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
        let todayName = japaneseWeekdays[todayWeekday - 1]
        return tests.filter { japaneseWeekdays.firstIndex(of: $0.weekday) ?? 7 >= todayWeekday }
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
                                    isPresentingDetail = true
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
                        Text("今週の小テストはありません")
                            .foregroundColor(.gray)
                            .italic()
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
                    }
                }
            }
            .navigationTitle("今日")
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $isPresentingDetail) {
                if let assignment = selectedAssignment {
                    TaskDetailSheet(
                        assignment: assignment,
                        onSave: { _ in isPresentingDetail = false },
                        onDelete: { isPresentingDetail = false }
                    )
                }
            }
        }
    }
}
