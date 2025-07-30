import Foundation
import SwiftUI
import UserNotifications

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var selectedDate: Date = Date()
    
    init() {
        loadTasks()
        setupTaskRollover()
        requestNotificationPermission()
    }
    
    // MARK: - Task Rollover Setup
    
    private func setupTaskRollover() {
        // Check for any missed rollovers when app starts
        checkAndRolloverTasks()
        
        // Schedule the next rollover check
        scheduleNextRollover()
        
        // Set up app lifecycle observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    @objc private func appDidBecomeActive() {
        // Check if we need to rollover tasks when app becomes active
        checkAndRolloverTasks()
    }
    
    private func scheduleNextRollover() {
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing rollover notifications
        center.removePendingNotificationRequests(withIdentifiers: ["taskRollover"])
        
        // Calculate next midnight
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Rollover"
        content.body = "Outstanding tasks have been moved to today"
        content.sound = .default
        
        // Create trigger for next midnight
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextMidnight),
            repeats: false
        )
        
        // Schedule the notification
        let request = UNNotificationRequest(identifier: "taskRollover", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling rollover notification: \(error)")
            }
        }
        
        // Also schedule a background task to run at midnight
        scheduleBackgroundTask(for: nextMidnight)
    }
    
    private func scheduleBackgroundTask(for date: Date) {
        // This would typically use BGTask framework for iOS 13+
        // For now, we'll rely on app becoming active and checking
        print("Background task scheduled for: \(date)")
    }
    
    private func checkAndRolloverTasks() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Check if we need to rollover tasks from yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        // Get outstanding tasks from yesterday
        let outstandingTasks = tasks.filter { task in
            calendar.isDate(task.date, inSameDayAs: yesterday) && !task.isCompleted
        }
        
        if !outstandingTasks.isEmpty {
            // Move outstanding tasks to today
            for task in outstandingTasks {
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].date = today
                }
            }
            
            saveTasks()
            
            // Schedule next rollover
            scheduleNextRollover()
            
            // Show notification if app is in background
            if UIApplication.shared.applicationState != .active {
                showRolloverNotification(count: outstandingTasks.count)
            }
        }
    }
    
    private func showRolloverNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Tasks Moved"
        content.body = "\(count) outstanding task\(count == 1 ? "" : "s") moved to today"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "rolloverComplete",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Manual Rollover
    
    func manuallyRolloverTasks() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Get all outstanding tasks from previous days
        let outstandingTasks = tasks.filter { task in
            let taskDate = calendar.startOfDay(for: task.date)
            return taskDate < today && !task.isCompleted
        }
        
        if !outstandingTasks.isEmpty {
            // Move all outstanding tasks to today
            for task in outstandingTasks {
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].date = today
                }
            }
            
            saveTasks()
            
            // Show notification
            showRolloverNotification(count: outstandingTasks.count)
        }
    }
    
    func getOutstandingTasksCount() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        return tasks.filter { task in
            let taskDate = calendar.startOfDay(for: task.date)
            return taskDate < today && !task.isCompleted
        }.count
    }
    
    // MARK: - Task Management
    
    func addTask(name: String, description: String, date: Date) {
        let task = Task(name: name, description: description, date: date)
        tasks.append(task)
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    func updateTask(_ task: Task, name: String, description: String, date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].name = name
            tasks[index].description = description
            tasks[index].date = date
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func moveTaskToNextDay(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].date = Calendar.current.date(byAdding: .day, value: 1, to: task.date) ?? task.date
            saveTasks()
        }
    }
    
    // MARK: - Date Navigation
    
    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    func goToToday() {
        selectedDate = Date()
    }
    
    // MARK: - Task Filtering
    
    func tasksForDate(_ date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            calendar.isDate(task.date, inSameDayAs: date)
        }.sorted { task1, task2 in
            if task1.isCompleted == task2.isCompleted {
                return task1.createdAt < task2.createdAt
            }
            return !task1.isCompleted && task2.isCompleted
        }
    }
    
    var currentDateTasks: [Task] {
        return tasksForDate(selectedDate)
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
} 