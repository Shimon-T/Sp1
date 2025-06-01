import SwiftUI

struct TimetableGridView: View {
    @AppStorage("periods") private var periodsData: Data = Data()
    private var periods: [ClassPeriod] {
        (try? JSONDecoder().decode([ClassPeriod].self, from: periodsData)) ?? []
    }
    
    @State private var storedTimetable: [[SubjectEntry?]] = []
    
    @State private var selectedRow: Int? = nil
    @State private var selectedColumn: Int? = nil
    @State private var subjectInput: String = ""
    @State private var teacherInput: String = ""
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }
    
    private func loadTimetableLimits() -> [Int] {
        let defaultLimits: [String: Int] = [
            "月曜日": 6, "火曜日": 6, "水曜日": 6, "木曜日": 6, "金曜日": 6, "土曜日": 4
        ]
        
        let weekdays = ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]

        if let data = UserDefaults.standard.data(forKey: "weekdayLimits"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            print("✅ 読み込まれた weekdayLimits: \(decoded)")
            return weekdays.map { decoded[$0] ?? 0 }
        }

        print("⚠️ weekdayLimits 未保存。デフォルトを使用")
        return weekdays.map { defaultLimits[$0] ?? 0 }
    }
    
    private var limits: [Int] {
        loadTimetableLimits()
    }

    private var timetable: [[SubjectEntry?]] {
        var result: [[SubjectEntry?]] = Array(repeating: Array(repeating: nil, count: days.count), count: limits.max() ?? 6)
        for row in 0..<min(storedTimetable.count, result.count) {
            for col in 0..<min(storedTimetable[row].count, days.count) {
                result[row][col] = storedTimetable[row][col]
            }
        }
        return result
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
                
                ForEach(0..<timetable.count, id: \.self) { row in
                    HStack(spacing: 0) {
                        Text("\(row+1)限")
                            .frame(width: 50)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(3)
                        
                        ForEach(0..<days.count, id: \.self) { column in
                            let maxRowForColumn = limits[column]

                            if row < maxRowForColumn {
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
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(Color.clear)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.trailing, 5)
            .navigationTitle("時間割")
            .task {
                if let data = UserDefaults.standard.data(forKey: "timetable"),
                   let decoded = try? JSONDecoder().decode([[SubjectEntry?]].self, from: data) {
                    storedTimetable = decoded
                }

                if periodsData.isEmpty {
                    let calendar = Calendar.current
                    let defaultPeriods = [
                        ClassPeriod(start: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 9, minute: 20, second: 0, of: Date())!),
                        ClassPeriod(start: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 10, minute: 20, second: 0, of: Date())!),
                        ClassPeriod(start: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 11, minute: 20, second: 0, of: Date())!),
                        ClassPeriod(start: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 12, minute: 20, second: 0, of: Date())!),
                        ClassPeriod(start: calendar.date(bySettingHour: 13, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 13, minute: 55, second: 0, of: Date())!),
                        ClassPeriod(start: calendar.date(bySettingHour: 14, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 14, minute: 55, second: 0, of: Date())!)
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
                                    var newTimetable = storedTimetable
                                    // Ensure newTimetable has enough rows
                                    while newTimetable.count <= row {
                                        newTimetable.append(Array(repeating: nil, count: days.count))
                                    }
                                    // Ensure each row has enough columns
                                    for i in 0..<newTimetable.count {
                                        while newTimetable[i].count < days.count {
                                            newTimetable[i].append(nil)
                                        }
                                    }
                                    newTimetable[row][column] = SubjectEntry(subject: subjectInput, teacher: teacherInput)
                                    storedTimetable = newTimetable
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
        if let encoded = try? JSONEncoder().encode(storedTimetable) {
            UserDefaults.standard.set(encoded, forKey: "timetable")
        }
    }
    
    private func loadTimetable() {
        if let data = UserDefaults.standard.data(forKey: "timetable"),
           let decoded = try? JSONDecoder().decode([[SubjectEntry?]].self, from: data) {
            storedTimetable = decoded
        }
    }
}
