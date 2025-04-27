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
            TimetableView()
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
                    Image(systemName: "checkmark.circle")
                    Text("課題")
                }
        }
    }
}

struct TimetableView: View {
    var body: some View {
        NavigationView {
            Text("ここに時間割を表示する予定")
                .navigationTitle("時間割")
        }
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
