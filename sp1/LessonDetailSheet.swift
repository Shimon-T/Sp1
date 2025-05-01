//
//  LessonDetailSheet.swift
//  sp1
//
//  Created by 田中志門 on 5/1/25.
//


import SwiftUI

struct LessonDetailSheet: View {
    let lesson: SubjectEntry
    let dayColumn: Int
    let timetable: [[SubjectEntry?]]
    let periods: [ClassPeriod]
    @Environment(\.dismiss) private var dismiss

    private var otherDays: [String: [Int]] {
        var result: [String: [Int]] = [:]
        for col in 0..<days.count {
            if col == dayColumn { continue }
            for row in 0..<timetable.count {
                if let l = timetable[row][col], l.subject == lesson.subject {
                    result[days[col], default: []].append(row + 1)
                }
            }
        }
        return result
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("教科")) {
                    Text(lesson.subject)
                }
                Section(header: Text("教師")) {
                    Text(lesson.teacher)
                }
                Section(header: Text("時間")) {
                    if let row = timetable.firstIndex(where: { $0[dayColumn]?.id == lesson.id }),
                       row < periods.count {
                        let period = periods[row]
                        Text("\(formattedTime(period.start))〜\(formattedTime(period.end))")
                    } else {
                        Text("時間情報なし")
                    }
                }
                Section(header: Text("他の曜日")) {
                    if otherDays.isEmpty {
                        Text("他の曜日にはありません")
                    } else {
                        ForEach(otherDays.sorted(by: { $0.key < $1.key }), id: \.key) { day, periods in
                            Text("\(day)曜 \(periods.map { "\($0)限" }.joined(separator: "・"))")
                        }
                    }
                }
                Section {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("授業の詳細")
        }
    }
}
