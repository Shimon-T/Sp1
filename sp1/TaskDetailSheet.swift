
import Foundation
import SwiftUI

struct TaskDetailSheet: View {
    @State var assignment: Assignment
    var onSave: (Assignment) -> Void
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("教科")) {
                    TextField("教科", text: $assignment.subject)
                }
                Section(header: Text("課題")) {
                    TextField("タイトル", text: $assignment.title)
                }
                Section(header: Text("締切")) {
                    DatePicker("締切", selection: $assignment.deadline, displayedComponents: .date)
                }
                Section(header: Text("提出方法")) {
                    TextField("例：Teamsに提出、印刷して提出など", text: $assignment.submissionMethod)
                }
                Section {
                    Button(role: .destructive) {
                        onDelete?()
                        dismiss()
                    } label: {
                        Text("削除")
                    }
                }
            }
            .navigationTitle("課題の詳細")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(assignment)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}
