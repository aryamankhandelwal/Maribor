import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let forestGreen = Color(red: 0.1, green: 0.4, blue: 0.2)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Todo Tab
            ContentView()
                .tabItem {
                    VStack {
                        Image(systemName: "checkmark")
                        Text("To do")
                            .font(.caption)
                    }
                }
                .tag(0)
            
            // Coming Soon Tab
            ComingSoonView()
                .tabItem {
                    VStack {
                        Image(systemName: "note.text")
                        Text("Notes")
                            .font(.caption)
                    }
                }
                .tag(1)
        }
        .accentColor(forestGreen)
        .background(Color.clear)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            
            // Add more padding to move icons lower
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.1, green: 0.4, blue: 0.2, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 8)
            appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 8)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ComingSoonView: View {
    var body: some View {
        ZStack {
            // Background image
            if let image = UIImage(named: "forest_background") {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            }
            
            // Dark overlay to make UI elements more visible
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Top navigation bar
                HStack {
                    Spacer()
                    Text("Maribor")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.4))
                
                VStack {
                    Spacer()
                    Text("Coming soon")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
} 