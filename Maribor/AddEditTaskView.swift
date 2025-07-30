import SwiftUI

struct AddEditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    let taskToEdit: Task?
    
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var taskDate = Date()
    
    init(taskManager: TaskManager, taskToEdit: Task? = nil) {
        self.taskManager = taskManager
        self.taskToEdit = taskToEdit
        
        if let task = taskToEdit {
            _taskName = State(initialValue: task.name)
            _taskDescription = State(initialValue: task.description)
            _taskDate = State(initialValue: task.date)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task name", text: $taskName)
                    
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Due date", selection: $taskDate, displayedComponents: .date)
                }
            }
            .navigationTitle(taskToEdit != nil ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveTask()
                    }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                    }
                    .disabled(taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let trimmedName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let task = taskToEdit {
            taskManager.updateTask(task, name: trimmedName, description: trimmedDescription, date: taskDate)
        } else {
            taskManager.addTask(name: trimmedName, description: trimmedDescription, date: taskDate)
        }
        
        dismiss()
    }
} 