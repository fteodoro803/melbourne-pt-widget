//
//  MelbournePTWidget.swift
//  MelbournePTWidget
//
//  Created by fteodoro803 on 25/2/2025.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    // Retrieves data from Flutter app
    private func getDataFromFlutter() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.melbournePTWidget")
        let textFromFlutterApp = userDefaults?.string(forKey: "text_from_flutter_app") ?? "No Text from Flutter"
        return SimpleEntry(date: Date(), text: textFromFlutterApp)
    }
    
    // Preview in Widget Gallery
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), text: "Preview in Widget Gallery")
    }

    // Widget Gallery/Selection preview
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
            SimpleEntry(date: Date(), text: "Widget Gallery/Selection")
    }
    
    // Actual Widget on Home Screen
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = getDataFromFlutter()

        return Timeline(entries: [entry], policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

// Widget Data Structure
struct SimpleEntry: TimelineEntry {
    let date: Date
    let text: String
}

// Appearance of Widget
struct MelbournePTWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Text:")
            Text(entry.text)
        }
    }
}

// Main Widget Configuration
struct MelbournePTWidget: Widget {
    let kind: String = "MelbournePTWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            MelbournePTWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    MelbournePTWidget()
} timeline: {
    SimpleEntry(date: .now, text: "Preview1")
    SimpleEntry(date: .now, text: "Preview2")
}
