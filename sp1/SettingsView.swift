import SwiftUI

struct SettingsView: View {
    @AppStorage("periods") private var periodsData: Data = {
        let calendar = Calendar.current
        let defaultPeriods = [
            ClassPeriod(start: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 9, minute: 20, second: 0, of: Date())!),
            ClassPeriod(start: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 10, minute: 20, second: 0, of: Date())!),
            ClassPeriod(start: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 11, minute: 20, second: 0, of: Date())!),
            ClassPeriod(start: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: Date())!, end: calendar.date(bySettingHour: 12, minute: 20, second: 0, of: Date())!),
            ClassPeriod(start: calendar.date(bySettingHour: 13, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 13, minute: 55, second: 0, of: Date())!),
            ClassPeriod(start: calendar.date(bySettingHour: 14, minute: 5, second: 0, of: Date())!, end: calendar.date(bySettingHour: 14, minute: 55, second: 0, of: Date())!)
        ]
        return try! JSONEncoder().encode(defaultPeriods)
    }()
    
    @State private var periods: [ClassPeriod] = []
    @State private var weekdayLimits: [String: Int] = [
        "月曜日": 6,
        "火曜日": 6,
        "水曜日": 6,
        "木曜日": 6,
        "金曜日": 6,
        "土曜日": 4
    ]

    var body: some View {
        NavigationView {
            Form {
                ForEach(periods.indices, id: \.self) { index in
                    HStack(alignment: .center, spacing: 12) {
                        Text("\(index + 1)限")
                            .frame(width: 40, alignment: .leading)
                            .font(.body)
                        Spacer()
                        Text("開始")
                            .font(.caption)
                        DatePicker("", selection: $periods[index].start, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .onChange(of: periods[index].start) { save() }
                        Text("終了")
                            .font(.caption)
                        DatePicker("", selection: $periods[index].end, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .onChange(of: periods[index].end) { save() }
                    }
                }
                Section(header: Text("曜日ごとの時限数")) {
                    ForEach(["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"], id: \.self) { day in
                        Stepper("\(day): \(weekdayLimits[day] ?? 0)限", value: Binding(
                            get: { weekdayLimits[day] ?? 0 },
                            set: {
                                weekdayLimits[day] = $0
                                save()
                            }
                        ), in: 0...10)
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                if let decoded = try? JSONDecoder().decode([ClassPeriod].self, from: periodsData) {
                    periods = decoded
                }
                if let limitsData = UserDefaults.standard.data(forKey: "weekdayLimits"),
                   let limitsDecoded = try? JSONDecoder().decode([String: Int].self, from: limitsData) {
                    weekdayLimits = limitsDecoded
                }
                print("Loaded periods: \(periods.count)")
                print("Loaded weekdayLimits: \(weekdayLimits)")
            }
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(periods) {
            periodsData = encoded
        }
        if let limitsEncoded = try? JSONEncoder().encode(weekdayLimits) {
            UserDefaults.standard.set(limitsEncoded, forKey: "weekdayLimits")
        }
        print("Saved periods: \(periods.count)")
        print("Saved weekdayLimits: \(weekdayLimits)")
    }
}
