# Maribor Widget Implementation

## Overview
The Maribor app now includes a WidgetKit widget that displays the user's top tasks in a small widget format.

## Widget Features

### Size Support
- **Small Size Only**: The widget only supports `.systemSmall` size as requested
- No medium or large size support implemented

### Content Display
- Shows the top 3 tasks in a vertical stack
- Displays task titles only (no descriptions)
- If there are more than 3 tasks, shows "+ X others" in gray text
- Uses mock data for now (5 sample tasks)

### Styling
- **Dark Mode Optimized**: Designed for dark mode with white text
- **Minimal Design**: Flat, clean interface prioritizing readability
- **Proper Spacing**: Optimized padding and spacing for small widget size

### Interaction
- **App Launch**: Tapping the widget opens the main Maribor app
- **URL Scheme**: Uses `maribor://open` URL scheme for navigation

## Technical Implementation

### Files Created/Modified
1. **MariborWidget/MariborWidget.swift** - Main widget implementation
2. **MariborWidget/Task.swift** - Task model for widget
3. **MariborWidget/MariborWidgetBundle.swift** - Widget bundle configuration
4. **Maribor/MariborApp.swift** - Added URL scheme handling

### Widget Structure
- `Provider`: TimelineProvider for widget data
- `TaskEntry`: TimelineEntry with tasks array
- `MariborWidgetEntryView`: SwiftUI view for widget display
- `MariborWidget`: Main widget configuration

### Mock Data
The widget currently uses 5 sample tasks:
1. "Complete project proposal"
2. "Review code changes"
3. "Team meeting"
4. "Update documentation"
5. "Prepare presentation"

## Future Enhancements
- Connect to real task data from the main app
- Add task completion status indicators
- Implement task priority sorting
- Add refresh timeline for real-time updates

## Building and Testing
1. Open the project in Xcode
2. Select the MariborWidgetExtension target
3. Build and run on a device or simulator
4. Add the widget to your home screen
5. Test tapping the widget to open the main app

## Notes
- The widget target was already configured in the Xcode project
- Removed unnecessary widget files (AppIntent, Control, LiveActivity)
- Widget is optimized for dark mode as requested
- URL scheme handling is implemented in the main app 