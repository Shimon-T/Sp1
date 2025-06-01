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
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TimetableGridView()
                    .tag(0)
                TestView()
                    .tag(1)
                TodayView()
                    .tag(2)
                TaskView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }

            HStack {
                tabItemView(title: "時間割", iconName: "calendar", tag: 0)
                tabItemView(title: "小テスト", iconName: "doc.text.magnifyingglass", tag: 1)
                tabItemView(title: "ホーム", iconName: "globe.asia.australia", tag: 2)
                tabItemView(title: "提出物", iconName: "text.page", tag: 3)
                tabItemView(title: "設定", iconName: "gearshape", tag: 4)
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(15)
            .padding(.bottom, 10)
        }
    }

    func tabItemView(title: String, iconName: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack {
                Spacer()
                Image(systemName: iconName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(selectedTab == tag ? .black : .gray)
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(selectedTab == tag ? .black : .gray)
                Spacer()
            }
            .frame(width: selectedTab == tag ? 120 : 80, height: 60)
            .background(selectedTab == tag ? Color.blue.opacity(0.4) : .clear)
            .cornerRadius(10)
        }
    }
}

#Preview {
    ContentView()
}
