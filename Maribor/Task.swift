import Foundation

struct Task: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var date: Date
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    
    init(name: String, description: String = "", date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.date = date
        self.createdAt = Date()
    }
} 