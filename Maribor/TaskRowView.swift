import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveToNextDay: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteThreshold: CGFloat = -60
    private let moveThreshold: CGFloat = 60
    private let forestGreen = Color(red: 0.1, green: 0.4, blue: 0.2)
    
    var body: some View {
        ZStack {
            // Background action buttons that get revealed
            HStack(spacing: 0) {
                // Move to next day button (left side)
                if offset > 0 {
                    VStack {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Move")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 60)
                    .background(Color.gray)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Delete button (right side)
                if offset < 0 {
                    Spacer()
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 60)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
            .zIndex(1) // Action buttons appear above task card
            
            // Main task card
            HStack {
                Button(action: {
                    // Haptic feedback for task completion
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onToggle()
                }) {
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
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .offset(x: offset)
            .zIndex(0) // Task card stays below action buttons
            .contentShape(Rectangle()) // Make entire area tappable
            .onTapGesture {
                // Haptic feedback for edit
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                onEdit()
            }
        }
        .padding(.horizontal, 0) // Remove horizontal padding to start from edge
        .contentShape(Rectangle()) // Make entire ZStack area responsive to gestures
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    isSwiping = true
                    // Progressive reveal - the more you swipe, the more the action button appears
                    let newOffset = value.translation.width
                    offset = max(-UIScreen.main.bounds.width, min(UIScreen.main.bounds.width, newOffset))
                }
                .onEnded { _ in
                    isSwiping = false
                    
                    if offset < deleteThreshold {
                        // Haptic feedback for delete
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                        
                        // Delete task with full screen wipe animation
                        withAnimation(.easeInOut(duration: 0.5)) {
                            offset = -UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onDelete()
                        }
                    } else if offset > moveThreshold {
                        // Haptic feedback for move to next day
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Move to next day with full screen wipe animation
                        withAnimation(.easeInOut(duration: 0.5)) {
                            offset = UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        .onAppear {
            // Ensure safe initialization
            offset = 0
        }
    }
} 