//
//  TaskView.swift
//  sp1
//
//  Created by 田中志門 on 5/1/25.
//

import Foundation
import SwiftUI
import UserNotifications

struct TaskView: View {
    @AppStorage("assignments") private var assignmentsData: Data = Data()
    @State private var assignments: [Assignment] = []
    @State private var newTaskTitle = ""
    @State private var newTaskSubject = ""
    @State private var newTaskDeadline = Date()
    @State private var newTaskSubmissionMethod = ""
    @State private var isPresentingAddSheet = false
    @State private var selectedAssignment: Assignment? = nil
    @State private var assignmentToDelete: Assignment? = nil
    @State private var isShowingDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    if assignments.isEmpty {
                        Text("課題はありません")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(assignments) { assignment in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(assignment.title)
                                        .font(.headline)
                                    Text(assignment.subject)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    let isOverdue = assignment.deadline < Date()
                                    Text("締切: \(formattedDate(assignment.deadline))")
                                        .font(.caption)
                                        .foregroundColor(isOverdue ? .red : .gray)
                                }
                                Spacer()
                                if assignment.isStarred {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                Button(action: {
                                    selectedAssignment = assignment
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let index = assignments.firstIndex(of: assignment) {
                                        assignments.remove(at: index)
                                        save()
                                    }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    if let index = assignments.firstIndex(of: assignment) {
                                        assignments[index].isStarred.toggle()
                                        save()
                                    }
                                } label: {
                                    Label("スター", systemImage: assignment.isStarred ? "star.slash" : "star.fill")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                }
            }
            .navigationTitle("課題")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear(perform: load)
            .sheet(isPresented: $isPresentingAddSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("新しい課題を追加")) {
                            TextField("教科", text: $newTaskSubject)
                            TextField("課題のタイトル", text: $newTaskTitle)
                            DatePicker("締切", selection: $newTaskDeadline, displayedComponents: .date)
                            TextField("提出方法", text: $newTaskSubmissionMethod)
                        }
                    }
                    .navigationTitle("課題を追加")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") {
                                isPresentingAddSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("追加") {
                                guard !newTaskTitle.isEmpty && !newTaskSubject.isEmpty else { return }
                                let newAssignment = Assignment(subject: newTaskSubject, title: newTaskTitle, deadline: newTaskDeadline, isStarred: false, submissionMethod: newTaskSubmissionMethod)
                                assignments.append(newAssignment)
                                save()
                                scheduleNotifications(for: newAssignment)
                                newTaskTitle = ""
                                newTaskSubject = ""
                                newTaskDeadline = Date()
                                newTaskSubmissionMethod = ""
                                isPresentingAddSheet = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedAssignment) { assignment in
                TaskDetailSheet(
                    assignment: assignment,
                    onSave: { updatedAssignment in
                        if let index = assignments.firstIndex(of: assignment) {
                            assignments[index] = updatedAssignment
                            save()
                        }
                        selectedAssignment = nil
                    },
                    onDelete: {
                        if let index = assignments.firstIndex(of: assignment) {
                            assignments.remove(at: index)
                            save()
                        }
                        selectedAssignment = nil
                    }
                )
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(assignments) {
            assignmentsData = encoded
        }
    }

    private func load() {
        if let decoded = try? JSONDecoder().decode([Assignment].self, from: assignmentsData) {
            assignments = decoded
        }
    }

    private func scheduleNotifications(for assignment: Assignment) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let calendar = Calendar.current
                let content = UNMutableNotificationContent()
                content.title = "課題の提出"
                content.body = "\(assignment.title)（\(assignment.subject)）の提出期限が近づいています"
                content.sound = .default

                let threeDaysBefore = calendar.date(byAdding: .day, value: -3, to: assignment.deadline)
                let deadlineDay = calendar.startOfDay(for: assignment.deadline)

                let triggerDates = [threeDaysBefore, deadlineDay]

                for (index, date) in triggerDates.compactMap({ $0 }).enumerated() {
                    var components = calendar.dateComponents([.year, .month, .day], from: date)
                    components.hour = 8
                    components.minute = 0
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let request = UNNotificationRequest(identifier: "\(assignment.id)-\(index)", content: content, trigger: trigger)
                    center.add(request)
                }
            }
        }
    }
}
