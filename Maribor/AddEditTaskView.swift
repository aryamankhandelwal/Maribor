import SwiftUI
import NaturalLanguage

struct AddEditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    let taskToEdit: Task?
    
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var taskDate = Date()
    @State private var nlpTimer: Timer?
    
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
                        .onChange(of: taskName) { _ in
                            scheduleNLPProcessing()
                        }
                    
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: taskDescription) { _ in
                            scheduleNLPProcessing()
                        }
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
    
    // MARK: - NLP Processing
    
    private func scheduleNLPProcessing() {
        // Cancel existing timer
        nlpTimer?.invalidate()
        
        // Schedule new timer with 1 second delay
        nlpTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            processNLP()
        }
    }
    
    private func processNLP() {
        let combinedText = "\(taskName) \(taskDescription)".lowercased()
        
        // Create a date detector
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        
        if let detector = detector {
            let range = NSRange(location: 0, length: combinedText.utf16.count)
            let matches = detector.matches(in: combinedText, options: [], range: range)
            
            for match in matches {
                if let date = match.date {
                    DispatchQueue.main.async {
                        self.taskDate = date
                    }
                    return
                }
            }
        }
        
        // Custom date parsing for common phrases
        let datePhrases = [
            "today": 0,
            "tomorrow": 1,
            "day after tomorrow": 2,
            "next week": 7,
            "next monday": getNextWeekday(2), // Monday = 2
            "next tuesday": getNextWeekday(3),
            "next wednesday": getNextWeekday(4),
            "next thursday": getNextWeekday(5),
            "next friday": getNextWeekday(6),
            "next saturday": getNextWeekday(7),
            "next sunday": getNextWeekday(1)
        ]
        
        for (phrase, days) in datePhrases {
            if combinedText.contains(phrase) {
                let calendar = Calendar.current
                let newDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
                DispatchQueue.main.async {
                    self.taskDate = newDate
                }
                return
            }
        }
    }
    
    private func getNextWeekday(_ weekday: Int) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        
        if todayWeekday <= weekday {
            return weekday - todayWeekday
        } else {
            return 7 - todayWeekday + weekday
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