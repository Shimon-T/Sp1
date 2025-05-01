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



#Preview {
    ContentView()
}
