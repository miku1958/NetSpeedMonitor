import AppKit

final class MenuBarIconGenerator {
    
    static func generateIcon(
        text: String,
        font: NSFont = .monospacedSystemFont(ofSize: 8, weight: .semibold)
    ) -> NSImage {
		let style = NSMutableParagraphStyle()
		style.alignment = .center

		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.paragraphStyle: style,
			.kern: 0,
		]

		let textSize = text.size(withAttributes: attributes)
		let image = NSImage(size: NSSize(width: textSize.width, height: 22), flipped: false) { rect in


            let textRect = NSRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
            return true
        }
        
        image.isTemplate = true
        return image
    }
}
