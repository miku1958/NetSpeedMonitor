import SwiftUI
import ServiceManagement

@main
struct NetSpeedMonitorApp: App {
    @StateObject private var menuBarState = MenuBarState()

	init() {
		let service = SMAppService.mainApp
		try! service.register()
	}

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(menuBarState)
        } label: {
            Image(nsImage: menuBarState.currentIcon)
                .tag("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)
    }
}
