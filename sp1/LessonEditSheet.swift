//
//  LessonEditSheet.swift
//  sp1
//
//  Created by 田中志門 on 5/1/25.
//


import SwiftUI

struct LessonEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject: String
    @State private var teacher: String
    var onSave: (SubjectEntry?) -> Void

    init(lesson: SubjectEntry?, onSave: @escaping (SubjectEntry?) -> Void) {
        _subject = State(initialValue: lesson?.subject ?? "")
        _teacher = State(initialValue: lesson?.teacher ?? "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("教科")) {
                    TextField("教科を入力", text: $subject)
                }
                Section(header: Text("教師")) {
                    TextField("教師名を入力", text: $teacher)
                }
                Section {
                    Button("削除") {
                        onSave(nil)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("授業の編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newLesson = SubjectEntry(subject: subject, teacher: teacher)
                        onSave(newLesson)
                        dismiss()
                    }
                }
            }
        }
    }
}
