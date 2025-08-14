import SwiftUI

struct MenuBarIconTextGroup: View, Equatable {
	let downloadSpeed: String
	let downloadMetric: String
	let uploadSpeed: String
	let uploadMetric: String

	var body: some View {
		Grid(
			alignment: .trailing,
			horizontalSpacing: 4,
			verticalSpacing: -1
		) {
			GridRow {
				Text(uploadSpeed)
				Text(uploadMetric)
			}
			GridRow {
				Text(downloadSpeed)
				Text(downloadMetric)
			}
		}
		.font(.system(size: 8, weight: .bold, design: .monospaced))
		.foregroundStyle(NSApplication.shared.effectiveAppearance.name == .aqua ? .black : .white)
	}
}


struct MenuBarIcon: View {
	@Environment(\.displayScale) var displayScale
	@Environment(\.colorScheme) private var colorScheme
	@State private var image = Image(systemName: "network")

	static let width: CGFloat = {
		let renderer = ImageRenderer(
			content: MenuBarIconTextGroup(
				downloadSpeed: "123.4",
				downloadMetric: "KB/s",
				uploadSpeed: "12.4",
				uploadMetric: "B/s"
			)
		)
		let image = renderer.nsImage!
		return image.size.width
	}()

	let textGroup: MenuBarIconTextGroup

	init(textGroup: MenuBarIconTextGroup) {
		self.textGroup = textGroup
	}

	var body: some View {
		image
			.onChange(of: textGroup) {
				DispatchQueue.main.async {
					render()
				}
			}
	}

	func render() {
		let renderer = ImageRenderer(
			content: textGroup
				.frame(width: Self.width)
		)

		// make sure and use the correct display scale for this device
		renderer.scale = displayScale
		if let image = renderer.nsImage {
			self.image = Image(nsImage: image)
		}
	}
}

#Preview {
	MenuBarIcon(
		textGroup: .init(
			downloadSpeed: "123.45",
			downloadMetric: "KB/s",
			uploadSpeed: "12.4",
			uploadMetric: "B/s"
		)
	)
}
