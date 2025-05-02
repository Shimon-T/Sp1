//
//  ContentView.swift
//  sp1
//
//  Created by 田中志門 on 4/27/25.
//

import SwiftUI
import UserNotifications

let days = ["月", "火", "水", "木", "金", "土"]

struct ContentView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            TimetableGridView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("時間割")
                }
                .tag(0)

            TodayView()
                .tabItem {
                    Image(systemName: "globe.asia.australia")
                    Text("今日")
                }
                .tag(1)

            TaskView()
                .tabItem {
                    Image(systemName: "text.page")
                    Text("提出物")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
