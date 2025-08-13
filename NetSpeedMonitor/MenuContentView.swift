import SwiftUI
import os.log

public var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "elegracer")

struct MenuContentView: View {
    @EnvironmentObject var menuBarState: MenuBarState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Section {
                HStack {
                    ForEach(NetSpeedUpdateInterval.allCases) { interval in
                        Toggle(
                            interval.displayName,
                            isOn: Binding(
                                get: { menuBarState.netSpeedUpdateInterval == interval },
                                set: { if $0 { menuBarState.netSpeedUpdateInterval = interval } }
                            )
                        )
                        .toggleStyle(.button)
                    }
                }
            } header: {
                Text("Update Interval")
            }

            Divider()
            
            Section {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .fixedSize()
    }
}
