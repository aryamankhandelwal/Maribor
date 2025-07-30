import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveToNextDay: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteThreshold: CGFloat = -100
    private let moveThreshold: CGFloat = 100
    private let forestGreen = Color(red: 0.1, green: 0.4, blue: 0.2)
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? forestGreen : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough(task.isCompleted)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isSwiping = true
                    offset = value.translation.width
                }
                .onEnded { _ in
                    isSwiping = false
                    
                    if offset < deleteThreshold {
                        // Delete task
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = -UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete()
                        }
                    } else if offset > moveThreshold {
                        // Move to next day
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onMoveToNextDay()
                        }
                    } else {
                        // Reset position
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            onEdit()
        }
        .overlay(
            HStack {
                if offset < 0 {
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                        .padding(.trailing)
                }
                
                if offset > 0 {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .clipShape(Circle())
                        .padding(.leading)
                    Spacer()
                }
            }
        )
    }
} 