//
//  ContentView.swift
//  sp1
//
//  Created by 田中志門 on 4/27/25.
//

import SwiftUI
import UserNotifications
import Foundation

let days = ["月", "火", "水", "木", "金", "土"]

struct ContentView: View {
    @State private var selectedTab = 2

    var body: some View {
        TabView(selection: $selectedTab) {
            TimetableGridView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("時間割")
                }
                .tag(0)

            TestView()
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("小テスト")
                }
                .tag(1)

            TodayView()
                .tabItem {
                    Image(systemName: "globe.asia.australia")
                    Text("ホーム")
                }
                .tag(2)

            TaskView()
                .tabItem {
                    Image(systemName: "text.page")
                    Text("提出物")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
