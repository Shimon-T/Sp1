//
//  ContentView.swift
//  sp1
//
//  Created by 田中志門 on 4/27/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    var body: some View {
        TabView {
            TimetableGridView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("時間割")
                }
            
            TodayView()
                .tabItem {
                    Image(systemName: "globe.asia.australia")
                    Text("今日")
                }
            
            TaskView()
                .tabItem {
                    Image(systemName: "text.page")
                    Text("提出物")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
        }
    }
}

let days = ["月", "火", "水", "木", "金", "土"]

struct Lesson: Identifiable, Codable, Equatable {
    let id: UUID
    var subject: String
    var teacher: String
    
    init(id: UUID = UUID(), subject: String, teacher: String) {
        self.id = id
        self.subject = subject
        self.teacher = teacher
    }
}

struct PeriodTime: Codable, Identifiable, Equatable {
    var id = UUID()
    var start: Date
    var end: Date
}

struct TimetableGridView: View {
    @AppStorage("periods") private var periodsData: Data = Data()
    private var periods: [PeriodTime] {
        (try? JSONDecoder().decode([PeriodTime].self, from: periodsData)) ?? []
    }
    
    @State private var timetable: [[Lesson?]] = Array(
        repeating: Array(repeating: nil, count: days.count),
        count: 6
    )
    
    @State private var selectedRow: Int? = nil
    @State private var selectedColumn: Int? = nil
    @State private var subjectInput: String = ""
    @State private var teacherInput: String = ""
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("")
                        .frame(width: 50)
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            .padding(5)
                    }
                }
                Divider()
                
                ForEach(0..<periods.count, id: \.self) { row in
                    HStack(spacing: 0) {
                        Text("\(row+1)限\n\(timeFormatter.string(from: periods[row].start))〜\(timeFormatter.string(from: periods[row].end))")
                            .frame(width: 50)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(3)
                        
                        ForEach(0..<days.count, id: \.self) { column in
                            Button(action: {
                                selectedRow = row
                                selectedColumn = column
                                if let lesson = timetable[row][column] {
                                    subjectInput = lesson.subject
                                    teacherInput = lesson.teacher
                                } else {
                                    subjectInput = ""
                                    teacherInput = ""
                                }
                            }) {
                                VStack {
                                    if let lesson = timetable[row][column] {
                                        Text(lesson.subject)
                                            .font(.body)
                                        Text(lesson.teacher)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("＋")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color(UIColor.secondarySystemBackground))
                                .border(Color.gray.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .navigationTitle("時間割")
            .onAppear {
                loadTimetable()
                if periodsData.isEmpty {
                    let calendar = Calendar.current
                    let defaultPeriods = [
                        PeriodTime(start: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 9, minute: 20, second: 0, of: Date())!),
                        PeriodTime(start: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 10, minute: 20, second: 0, of: Date())!),
                        PeriodTime(start: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 11, minute: 20, second: 0, of: Date())!),
                        PeriodTime(start: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 12, minute: 20, second: 0, of: Date())!),
                        PeriodTime(start: calendar.date(bySettingHour: 13, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 13, minute: 55, second: 0, of: Date())!),
                        PeriodTime(start: calendar.date(bySettingHour: 14, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 14, minute: 55, second: 0, of: Date())!)
                    ]
                    if let encoded = try? JSONEncoder().encode(defaultPeriods) {
                        periodsData = encoded
                    }
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedRow != nil && selectedColumn != nil },
                set: { if !$0 { selectedRow = nil; selectedColumn = nil } }
            )) {
                if let row = selectedRow, let column = selectedColumn {
                    NavigationView {
                        Form {
                            Section(header: Text("科目名")) {
                                TextField("例：数学", text: $subjectInput)
                            }
                            Section(header: Text("先生名")) {
                                TextField("例：田中先生", text: $teacherInput)
                            }
                        }
                        .navigationTitle("\(days[column])曜 \(row+1)限")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("保存") {
                                    timetable[row][column] = Lesson(subject: subjectInput, teacher: teacherInput)
                                    saveTimetable()
                                    selectedRow = nil
                                    selectedColumn = nil
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("キャンセル") {
                                    selectedRow = nil
                                    selectedColumn = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveTimetable() {
        if let encoded = try? JSONEncoder().encode(timetable) {
            UserDefaults.standard.set(encoded, forKey: "timetable")
        }
    }
    
    private func loadTimetable() {
        if let savedData = UserDefaults.standard.data(forKey: "timetable"),
           let decoded = try? JSONDecoder().decode([[Lesson?]].self, from: savedData) {
            timetable = decoded
        }
    }
}

struct SettingsView: View {
    @AppStorage("periods") private var periodsData: Data = {
        let calendar = Calendar.current
        let defaultPeriods = [
            PeriodTime(start: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 9, minute: 20, second: 0, of: Date())!),
            PeriodTime(start: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 10, minute: 20, second: 0, of: Date())!),
            PeriodTime(start: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 11, minute: 20, second: 0, of: Date())!),
            PeriodTime(start: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 12, minute: 20, second: 0, of: Date())!),
            PeriodTime(start: calendar.date(bySettingHour: 13, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 13, minute: 55, second: 0, of: Date())!),
            PeriodTime(start: calendar.date(bySettingHour: 14, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 14, minute: 55, second: 0, of: Date())!)
        ]
        return try! JSONEncoder().encode(defaultPeriods)
    }()
    
    @State private var periods: [PeriodTime] = []
    @State private var selectedPeriodIndex: Int? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(periods.indices, id: \.self) { index in
                        Button(action: {
                            selectedPeriodIndex = index
                        }) {
                            HStack {
                                Text("\(index + 1)限")
                                Spacer()
                                Text(formattedTime(periods[index]))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                if let selectedIndex = selectedPeriodIndex {
                    Form {
                        Section(header: Text("\(selectedIndex + 1)限の時間を編集")) {
                            DatePicker("開始", selection: $periods[selectedIndex].start, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.inline)
                            DatePicker("終了", selection: $periods[selectedIndex].end, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.inline)
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
            .navigationTitle("時間設定")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let encoded = try? JSONEncoder().encode(periods) {
                            periodsData = encoded
                        }
                    }
                }
            }
            .onAppear {
                if let decoded = try? JSONDecoder().decode([PeriodTime].self, from: periodsData) {
                    periods = decoded
                }
            }
            // Transparent overlay to dismiss pickers when tapping outside
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPeriodIndex = nil
                    }
            )
        }
    }
    
    private func formattedTime(_ period: PeriodTime) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: period.start))〜\(formatter.string(from: period.end))"
    }
}

struct TodayView: View {
    @AppStorage("timetable") private var timetableData: Data = Data()
    @AppStorage("periods") private var periodsData: Data = Data()

    private var timetable: [[Lesson?]] {
        (try? JSONDecoder().decode([[Lesson?]].self, from: timetableData)) ?? []
    }

    private var periods: [PeriodTime] {
        (try? JSONDecoder().decode([PeriodTime].self, from: periodsData)) ?? []
    }

    // Helper to get today's column index (0=月, ..., 5=土), or nil for Sunday
    private var todayColumn: Int? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) // 1=Sun, 2=Mon...
        if weekday == 1 { return nil }
        let column = weekday - 2
        return (column >= 0 && column < 6) ? column : nil
    }

    // Used for displaying today's lessons as [Lesson?]
    private var todayLessons: [Lesson?] {
        guard let column = todayColumn else { return [] }
        return timetable.map { row in
            if row.indices.contains(column) {
                return row[column]
            } else {
                return nil
            }
        }
    }


    let upcomingTasks = [
        ("国語のレポート", "4/28提出"),
        ("化学の宿題", "4/29提出")
    ]

    @State private var selectedLessonIndex: Int? = nil
    @State private var isShowingDetail: Bool = false
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("今日の時間割")) {
                    if todayColumn == nil {
                        Text("今日は日曜日です")
                            .padding(.vertical, 8)
                    } else if todayLessons.allSatisfy({ $0 == nil }) {
                        Text("今日は授業はありません")
                            .padding(.vertical, 8)
                    } else {
                        ForEach(todayLessons.indices, id: \.self) { i in
                            if let lesson = todayLessons[i] {
                                let period = i
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(period + 1)限: \(lesson.subject)")
                                        if !lesson.teacher.isEmpty {
                                            Text(lesson.teacher)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        selectedLessonIndex = i
                                        isShowingDetail = true
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                Section(header: Text("提出期限が近い課題")) {
                    ForEach(upcomingTasks, id: \.0) { task in
                        VStack(alignment: .leading) {
                            Text(task.0)
                            Text(task.1)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("今日")
            
            .sheet(isPresented: $isShowingDetail) {
                if let idx = selectedLessonIndex,
                   let lesson = todayLessons.indices.contains(idx) ? todayLessons[idx] : nil,
                   let column = todayColumn {
                    LessonDetailSheet(lesson: lesson, period: idx, periods: periods, dayColumn: column, timetable: timetable)
                }
            }
        }
    }
}

struct LessonDetailSheet: View {
    let lesson: Lesson
    let period: Int
    let periods: [PeriodTime]
    let dayColumn: Int
    let timetable: [[Lesson?]]

    private var otherDays: [String] {
        // Find which other days this subject appears in timetable (excluding today)
        var daysFound: [String] = []
        for col in 0..<days.count {
            if col == dayColumn { continue }
            for row in 0..<timetable.count {
                if let l = timetable[row][col], l.subject == lesson.subject {
                    if !daysFound.contains(days[col]) {
                        daysFound.append(days[col])
                    }
                }
            }
        }
        return daysFound
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("科目名")) {
                    Text(lesson.subject)
                }
                if !lesson.teacher.isEmpty {
                    Section(header: Text("先生名")) {
                        Text(lesson.teacher)
                    }
                }
                if period < periods.count {
                    Section(header: Text("時間")) {
                        Text("\(timeFormatter.string(from: periods[period].start))〜\(timeFormatter.string(from: periods[period].end))")
                    }
                }
                Section(header: Text("他の曜日")) {
                    if otherDays.isEmpty {
                        Text("他の曜日にはありません")
                    } else {
                        Text(otherDays.joined(separator: "・"))
                    }
                }
            }
            .navigationTitle("授業詳細")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        // Dismiss handled by .sheet in parent view
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }

        }
    }
}


#Preview {
    ContentView()
}
