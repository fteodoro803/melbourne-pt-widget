//
//  MelbournePTWidgetLiveActivity.swift
//  MelbournePTWidget
//
//  Created by fteodoro803 on 25/2/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MelbournePTWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MelbournePTWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MelbournePTWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MelbournePTWidgetAttributes {
    fileprivate static var preview: MelbournePTWidgetAttributes {
        MelbournePTWidgetAttributes(name: "World")
    }
}

extension MelbournePTWidgetAttributes.ContentState {
    fileprivate static var smiley: MelbournePTWidgetAttributes.ContentState {
        MelbournePTWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MelbournePTWidgetAttributes.ContentState {
         MelbournePTWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MelbournePTWidgetAttributes.preview) {
   MelbournePTWidgetLiveActivity()
} contentStates: {
    MelbournePTWidgetAttributes.ContentState.smiley
    MelbournePTWidgetAttributes.ContentState.starEyes
}
