import SwiftUI
import Combine
import SystemConfiguration

enum NetSpeedUpdateInterval: Int, CaseIterable, Identifiable {
    case Sec1 = 1
    case Sec2 = 2
    case Sec5 = 5
    case Sec10 = 10
    case Sec30 = 30
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .Sec1: return "1s"
        case .Sec2: return "2s"
        case .Sec5: return "5s"
        case .Sec10: return "10s"
        case .Sec30: return "30s"
        }
    }
}

class MenuBarState: ObservableObject {
    @AppStorage("NetSpeedUpdateInterval") var netSpeedUpdateInterval: NetSpeedUpdateInterval = .Sec1 {
        didSet { updateNetSpeedUpdateIntervalStatus() }
    }
	@Published var menuBarIcon: MenuBarIcon?
    
    private var timer: Timer?
    private var primaryInterface: String?
    private var netTrafficStat = NetTrafficStatReceiver()

    private let speedMetrics: [String] = ["B", "KB", "MB", "GB", "TB"]
    
    private func updateNetSpeedUpdateIntervalStatus() {
		logger.info("netSpeedUpdateInterval, \(self.netSpeedUpdateInterval.displayName)")
        stopTimer()
        startTimer()
    }
    
    private func findPrimaryInterface() -> String? {
        let storeRef = SCDynamicStoreCreate(nil, "FindCurrentInterfaceIpMac" as CFString, nil, nil)
        let global = SCDynamicStoreCopyValue(storeRef, "State:/Network/Global/IPv4" as CFString)
        let primaryInterface = global?.value(forKey: "PrimaryInterface") as? String
        return primaryInterface
    }
    
    private func startTimer() {
		let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(netSpeedUpdateInterval.rawValue), repeats: true) { [weak self] _ in
			self?.updateNetSpeed()
		}
		RunLoop.current.add(timer, forMode: .common)
		self.timer = timer
        logger.info("startTimer")
    }

	private func updateNetSpeed() {
		primaryInterface = findPrimaryInterface()
		if (primaryInterface == nil) { return }

		if let netTrafficStatMap = netTrafficStat.getNetTrafficStatMap() {
			if let netTrafficStat = netTrafficStatMap.object(forKey: primaryInterface!) as? NetTrafficStatOC  {
				var downloadSpeed = netTrafficStat.ibytes_per_sec as! Double
				var uploadSpeed = netTrafficStat.obytes_per_sec as! Double
				var downloadMetric = speedMetrics.first!
				var uploadMetric = speedMetrics.first!
				for metric in speedMetrics.dropFirst() {
					if downloadSpeed > 1000.0 {
						downloadSpeed /= 1024.0
						downloadMetric = metric
					}
					if uploadSpeed > 1000.0 {
						uploadSpeed /= 1024.0
						uploadMetric = metric
					}
				}
				typealias StringLength = (integer: Int, decimal: Int)
				func stringLength(_ speed: Double) -> StringLength {
					var length: StringLength = (1, 0)
					var speed = speed
					while speed > 10 {
						speed /= 10
						length.integer += 1
					}
					while speed - Double(Int(speed)) > 0 {
						speed *= 10
						length.decimal += 1
					}
					while length.integer + length.decimal < 4 {
						length.decimal += 1
					}
					if length.decimal > 2 {
						length.decimal = 2
					}
					if length.integer + length.decimal > 4 {
						length.decimal = 4 - length.integer
					}

					return length
				}

				let length = stringLength(max(downloadSpeed, uploadSpeed))
				menuBarIcon = .init(
					textGroup: .init(
						uploadSpeed: String(format: "%.\(length.decimal)lf", uploadSpeed),
						uploadMetric: "\(uploadMetric)/s",
						downloadSpeed: String(format: "%.\(length.decimal)lf", downloadSpeed),
						downloadMetric: "\(downloadMetric)/s"
					)
				)

				logger.info("deltaIn: \(String(format:"%.6f", downloadSpeed)) \(downloadMetric)/s, deltaOut: \(String(format:"%.6f", uploadSpeed)) \(uploadMetric)/s")
			}
		}
	}

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        logger.info("stopTimer")
    }
    
    init() {
		updateNetSpeed()
        DispatchQueue.main.async { [self] in
			updateNetSpeed()
            startTimer()
        }
    }
    
    deinit {
        DispatchQueue.main.async { [self] in
            stopTimer()
        }
    }
}

