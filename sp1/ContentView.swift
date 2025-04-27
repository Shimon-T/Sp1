//
//  ContentView.swift
//  sp1
//
//  Created by 田中志門 on 4/27/25.
//

import SwiftUI

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
                    Text("課題")
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
                    VStack(spacing: 10) {
                        Text("\(selectedIndex + 1)限の時間を編集")
                            .font(.headline)
                        
                        HStack {
                            VStack {
                                Text("開始")
                                    .font(.subheadline)
                                DatePicker("", selection: $periods[selectedIndex].start, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                            VStack {
                                Text("終了")
                                    .font(.subheadline)
                                DatePicker("", selection: $periods[selectedIndex].end, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding()
                    }
                    .animation(.easeInOut, value: selectedPeriodIndex)
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
        }
    }
    
    private func formattedTime(_ period: PeriodTime) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: period.start))〜\(formatter.string(from: period.end))"
    }
}

struct TodayView: View {
    // 仮のデータ（あとで本物のデータに入れ替える想定）
    let todaySchedule = [
        "1限: 数学",
        "2限: 英語",
        "3限: 物理"
    ]
    
    let upcomingTasks = [
        ("国語のレポート", "4/28提出"),
        ("化学の宿題", "4/29提出")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("今日の時間割")) {
                    ForEach(todaySchedule, id: \.self) { subject in
                        Text(subject)
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
        }
    }
}

struct TaskView: View {
    var body: some View {
        NavigationView {
            Text("ここに課題リストを表示する予定")
                .navigationTitle("課題")
        }
    }
}

#Preview {
    ContentView()
}
