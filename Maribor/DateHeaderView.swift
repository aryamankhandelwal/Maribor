import SwiftUI

struct DateHeaderView: View {
    @ObservedObject var taskManager: TaskManager
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = taskManager.selectedDate
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private let forestGreen = Color(red: 0.1, green: 0.4, blue: 0.2)
    
    var body: some View {
        VStack(spacing: 12) {
            // Week day numbers
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 4) {
                        let isToday = Calendar.current.isDateInToday(date)
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: taskManager.selectedDate)
                        
                        if isToday {
                            // Today's date - always filled green circle
                            Text(dayFormatter.string(from: date))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(forestGreen)
                                .clipShape(Circle())
                        } else if isSelected {
                            // Selected date (but not today) - outlined green circle
                            Text(dayFormatter.string(from: date))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(forestGreen)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(forestGreen, lineWidth: 2)
                                )
                        } else {
                            // Regular date
                            Text(dayFormatter.string(from: date))
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Date header with chevrons
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        taskManager.goToPreviousDay()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(forestGreen)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(dateFormatter.string(from: taskManager.selectedDate))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(forestGreen)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                taskManager.goToToday()
                            }
                        }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        taskManager.goToNextDay()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(forestGreen)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
} 