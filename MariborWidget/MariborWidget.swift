//
//  MariborWidget.swift
//  MariborWidget
//
//  Created by Aryaman on 7/31/25.
//

import WidgetKit
import SwiftUI

// Simple data accessor for widget to read tasks from UserDefaults
struct WidgetDataAccessor {
    static func getIncompleteTasksForToday() -> [Task] {
        guard let data = UserDefaults.standard.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([Task].self, from: data) else {
            return []
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return tasks.filter { task in
            calendar.isDate(task.date, inSameDayAs: today) && !task.isCompleted
        }.sorted { task1, task2 in
            task1.createdAt < task2.createdAt
        }
    }
}

struct Provider: TimelineProvider {
    typealias Entry = TaskEntry
    
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let incompleteTasks = WidgetDataAccessor.getIncompleteTasksForToday()
        let entry = TaskEntry(date: Date(), tasks: incompleteTasks)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let incompleteTasks = WidgetDataAccessor.getIncompleteTasksForToday()
        let entry = TaskEntry(date: Date(), tasks: incompleteTasks)
        
        // Update every 15 minutes to keep widget fresh
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [Task]
}

struct MariborWidgetEntryView : View {
    var entry: TaskEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemSmall {
            // Small widget content with Things-inspired design
            VStack(alignment: .leading, spacing: 8) {
                // Header with "Today" text and task count badge
                HStack {
                    Text("Today")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Task count badge - show total incomplete tasks
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                        Text("\(entry.tasks.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // Show top 3 incomplete tasks with bullet points
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(entry.tasks.prefix(3)), id: \.id) { task in
                        HStack(alignment: .top, spacing: 8) {
                            // Bullet point (empty circle) - made much bigger for obvious clickability
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                .frame(width: 16, height: 16)
                                .padding(.top, 0)
                            
                            // Task text - using smaller font size
                            Text(task.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                // Show remaining count if more than 3 incomplete tasks
                if entry.tasks.count > 3 {
                    let remainingCount = entry.tasks.count - 3
                    Text("+ \(remainingCount) others")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.black)
            .widgetURL(URL(string: "maribor://open"))
        } else {
            // For all other sizes, show a placeholder
            VStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Maribor Tasks")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Small widget only")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(URL(string: "maribor://open"))
        }
    }
}

struct MariborWidget: Widget {
    let kind: String = "MariborWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MariborWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Maribor Tasks")
        .description("Shows your top tasks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Preview only for small size
#Preview(as: .systemSmall) {
    MariborWidget()
} timeline: {
    TaskEntry(date: .now, tasks: [])
}
