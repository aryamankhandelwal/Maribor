import SwiftUI
import NaturalLanguage

extension NSTextCheckingResult {
    func capturedString(in string: String, at index: Int) -> String? {
        guard index < numberOfRanges else { return nil }
        let range = range(at: index)
        guard range.location != NSNotFound else { return nil }
        return (string as NSString).substring(with: range)
    }
}

struct AddEditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    let taskToEdit: Task?
    
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var taskDate = Date()
    @State private var nlpTimer: Timer?
    @FocusState private var isTaskNameFocused: Bool
    @FocusState private var isTaskDescriptionFocused: Bool
    
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
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("Task Details")) {
                        TextField("Task name", text: $taskName)
                            .focused($isTaskNameFocused)
                            .onChange(of: taskName) {
                                scheduleNLPProcessing()
                            }
                            .onSubmit {
                                isTaskDescriptionFocused = true
                            }
                            .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(false)
                            .submitLabel(.next)
                        
                        TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                            .focused($isTaskDescriptionFocused)
                            .lineLimit(3...6)
                            .onChange(of: taskDescription) {
                                scheduleNLPProcessing()
                            }
                            .onSubmit {
                                isTaskDescriptionFocused = false
                            }
                            .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(false)
                            .submitLabel(.done)
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
                
                // Spacer to push content up when keyboard appears
                Spacer(minLength: 0)
            }
            .onAppear {
                // Focus the task name field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTaskNameFocused = true
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                isTaskNameFocused = false
                isTaskDescriptionFocused = false
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
                        self.cleanupTextAfterDateDetection()
                    }
                    return
                }
            }
        }
        
        // Enhanced date parsing for common phrases
        let datePhrases: [(String, Int)] = [
            ("today", 0),
            ("tomorrow", 1),
            ("day after tomorrow", 2),
            ("next week", 7),
            ("next monday", getNextWeekday(2)),
            ("next tuesday", getNextWeekday(3)),
            ("next wednesday", getNextWeekday(4)),
            ("next thursday", getNextWeekday(5)),
            ("next friday", getNextWeekday(6)),
            ("next saturday", getNextWeekday(7)),
            ("next sunday", getNextWeekday(1)),
            ("on monday", getNextWeekday(2)),
            ("on tuesday", getNextWeekday(3)),
            ("on wednesday", getNextWeekday(4)),
            ("on thursday", getNextWeekday(5)),
            ("on friday", getNextWeekday(6)),
            ("on saturday", getNextWeekday(7)),
            ("on sunday", getNextWeekday(1)),
            ("this monday", getNextWeekday(2)),
            ("this tuesday", getNextWeekday(3)),
            ("this wednesday", getNextWeekday(4)),
            ("this thursday", getNextWeekday(5)),
            ("this friday", getNextWeekday(6)),
            ("this saturday", getNextWeekday(7)),
            ("this sunday", getNextWeekday(1))
        ]
        
        // Check for "X days from now" pattern with simplified regex
        if combinedText.contains("days from now") {
            let pattern = try? NSRegularExpression(pattern: "(\\d+)\\s*days?\\s*from\\s*now", options: .caseInsensitive)
            if let regex = pattern {
                let range = NSRange(location: 0, length: combinedText.utf16.count)
                let matches = regex.matches(in: combinedText, options: [], range: range)
                
                for match in matches {
                    if let daysString = match.capturedString(in: combinedText, at: 1),
                       let days = Int(daysString) {
                        let calendar = Calendar.current
                        let newDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
                        DispatchQueue.main.async {
                            self.taskDate = newDate
                            self.cleanupTextAfterDateDetection()
                        }
                        return
                    }
                }
            }
        }
        
        // Check for "X days later" pattern with simplified regex
        if combinedText.contains("days later") {
            let pattern = try? NSRegularExpression(pattern: "(\\d+)\\s*days?\\s*later", options: .caseInsensitive)
            if let regex = pattern {
                let range = NSRange(location: 0, length: combinedText.utf16.count)
                let matches = regex.matches(in: combinedText, options: [], range: range)
                
                for match in matches {
                    if let daysString = match.capturedString(in: combinedText, at: 1),
                       let days = Int(daysString) {
                        let calendar = Calendar.current
                        let newDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
                        DispatchQueue.main.async {
                            self.taskDate = newDate
                            self.cleanupTextAfterDateDetection()
                        }
                        return
                    }
                }
            }
        }
        
        // Check for specific date phrases (longest first to avoid partial matches)
        let sortedPhrases = datePhrases.sorted { $0.0.count > $1.0.count }
        
        for (phrase, days) in sortedPhrases {
            if combinedText.contains(phrase) {
                let calendar = Calendar.current
                let newDate = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
                DispatchQueue.main.async {
                    self.taskDate = newDate
                    self.cleanupTextAfterDateDetection()
                }
                return
            }
        }
    }
    
    private func cleanupTextAfterDateDetection() {
        // Comprehensive list of date-related words and phrases to remove
        let dateWords = [
            "today", "tomorrow", "day after tomorrow", "next week",
            "next monday", "next tuesday", "next wednesday", "next thursday", 
            "next friday", "next saturday", "next sunday",
            "on monday", "on tuesday", "on wednesday", "on thursday",
            "on friday", "on saturday", "on sunday",
            "this monday", "this tuesday", "this wednesday", "this thursday",
            "this friday", "this saturday", "this sunday"
        ]
        
        // Remove date-related words from task name (longest first)
        var cleanedName = taskName
        for word in dateWords.sorted(by: { $0.count > $1.count }) {
            cleanedName = cleanedName.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        
        // Remove "X days from now" and "X days later" patterns
        let daysPatterns = [
            try? NSRegularExpression(pattern: "\\d+\\s*days?\\s*from\\s*now", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\d+\\s*days?\\s*later", options: .caseInsensitive)
        ]
        
        for pattern in daysPatterns {
            if let regex = pattern {
                let range = NSRange(location: 0, length: cleanedName.utf16.count)
                if range.length > 0 {
                    cleanedName = regex.stringByReplacingMatches(in: cleanedName, options: [], range: range, withTemplate: "")
                }
            }
        }
        
        // Remove date patterns like "on Aug 30", "on 30 Aug", etc.
        let datePatterns = [
            try? NSRegularExpression(pattern: "\\s*on\\s+\\w+\\s+\\d+", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\s*on\\s+\\d+\\s+\\w+", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\s*\\d+\\s+\\w+", options: .caseInsensitive),
            try? NSRegularExpression(pattern: "\\s*\\w+\\s+\\d+", options: .caseInsensitive)
        ]
        
        for pattern in datePatterns {
            if let regex = pattern {
                let range = NSRange(location: 0, length: cleanedName.utf16.count)
                if range.length > 0 {
                    cleanedName = regex.stringByReplacingMatches(in: cleanedName, options: [], range: range, withTemplate: "")
                }
            }
        }
        
        // Clean up extra spaces and punctuation
        cleanedName = cleanedName.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanedName = cleanedName.replacingOccurrences(of: "\\s*,\\s*", with: ", ", options: .regularExpression)
        cleanedName = cleanedName.replacingOccurrences(of: "\\s*\\.\\s*", with: ". ", options: .regularExpression)
        cleanedName = cleanedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only update if we actually cleaned something and it's not empty
        if cleanedName != taskName && !cleanedName.isEmpty {
            taskName = cleanedName
        }
        
        // Also clean description
        var cleanedDescription = taskDescription
        for word in dateWords.sorted(by: { $0.count > $1.count }) {
            cleanedDescription = cleanedDescription.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        
        for pattern in daysPatterns {
            if let regex = pattern {
                let range = NSRange(location: 0, length: cleanedDescription.utf16.count)
                if range.length > 0 {
                    cleanedDescription = regex.stringByReplacingMatches(in: cleanedDescription, options: [], range: range, withTemplate: "")
                }
            }
        }
        
        for pattern in datePatterns {
            if let regex = pattern {
                let range = NSRange(location: 0, length: cleanedDescription.utf16.count)
                if range.length > 0 {
                    cleanedDescription = regex.stringByReplacingMatches(in: cleanedDescription, options: [], range: range, withTemplate: "")
                }
            }
        }
        
        cleanedDescription = cleanedDescription.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanedDescription = cleanedDescription.replacingOccurrences(of: "\\s*,\\s*", with: ", ", options: .regularExpression)
        cleanedDescription = cleanedDescription.replacingOccurrences(of: "\\s*\\.\\s*", with: ". ", options: .regularExpression)
        cleanedDescription = cleanedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedDescription != taskDescription {
            taskDescription = cleanedDescription
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