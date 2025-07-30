//
//  ContentView.swift
//  Maribor
//
//  Created by Aryaman on 7/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var showingRolloverAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DateHeaderView(taskManager: taskManager)
                
                // Outstanding tasks indicator
                if taskManager.getOutstandingTasksCount() > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("\(taskManager.getOutstandingTasksCount()) outstanding task\(taskManager.getOutstandingTasksCount() == 1 ? "" : "s") from previous days")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Move to Today") {
                            showingRolloverAlert = true
                        }
                        .font(.caption)
                        .foregroundColor(Color(red: 0.1, green: 0.4, blue: 0.2))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                }
                
                if taskManager.currentDateTasks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("No tasks")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(taskManager.currentDateTasks) { task in
                                TaskRowView(
                                    task: task,
                                    onToggle: {
                                        taskManager.toggleTaskCompletion(task)
                                    },
                                    onEdit: {
                                        taskToEdit = task
                                    },
                                    onDelete: {
                                        taskManager.deleteTask(task)
                                    },
                                    onMoveToNextDay: {
                                        taskManager.moveTaskToNextDay(task)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                Spacer()
                // Floating Action Button
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.1, green: 0.4, blue: 0.2))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddEditTaskView(taskManager: taskManager)
                    .presentationDetents([.fraction(0.75)])
            }
            .sheet(item: $taskToEdit) { task in
                AddEditTaskView(taskManager: taskManager, taskToEdit: task)
                    .presentationDetents([.fraction(0.75)])
            }
            .alert("Move Outstanding Tasks", isPresented: $showingRolloverAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Move to Today") {
                    taskManager.manuallyRolloverTasks()
                }
            } message: {
                Text("Move \(taskManager.getOutstandingTasksCount()) outstanding task\(taskManager.getOutstandingTasksCount() == 1 ? "" : "s") from previous days to today?")
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
