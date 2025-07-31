//
//  MariborWidget.swift
//  MariborWidget
//
//  Created by Aryaman on 7/31/25.
//

import WidgetKit
import SwiftUI

// Mock task data for the widget
struct MockTaskData {
    static let sampleTasks: [Task] = [
        Task(name: "Borrow Sarah's travel guide", description: "Get the travel guide from Sarah", date: Date()),
        Task(name: "Finish expense report", description: "Complete the quarterly expense report", date: Date()),
        Task(name: "Review quarterly data with Olivia", description: "Go through the quarterly data", date: Date()),
        Task(name: "Prepare presentation slides", description: "Create slides for the meeting", date: Date()),
        Task(name: "Update project documentation", description: "Update the project docs", date: Date()),
        Task(name: "Schedule team meeting", description: "Set up the weekly team sync", date: Date()),
        Task(name: "Review code changes", description: "Review the latest PR", date: Date()),
        Task(name: "Order office supplies", description: "Order new supplies", date: Date()),
        Task(name: "Call client about project", description: "Follow up with the client", date: Date())
    ]
}

struct Provider: TimelineProvider {
    typealias Entry = TaskEntry
    
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: MockTaskData.sampleTasks)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let entry = TaskEntry(date: Date(), tasks: MockTaskData.sampleTasks)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let entry = TaskEntry(date: Date(), tasks: MockTaskData.sampleTasks)
        let timeline = Timeline(entries: [entry], policy: .never)
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
                    
                    // Task count badge
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                        Text("\(entry.tasks.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                // Show top 3 tasks with bullet points
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
                
                // Show remaining count if more than 3 tasks
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
    TaskEntry(date: .now, tasks: MockTaskData.sampleTasks)
}
