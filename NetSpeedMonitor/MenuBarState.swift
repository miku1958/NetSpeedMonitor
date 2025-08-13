import SwiftUI
import Combine
import SystemConfiguration

enum NetSpeedUpdateInterval: Int, CaseIterable, Identifiable {
    case Sec1 = 1
    case Sec2 = 2
    case Sec5 = 5
    case Sec10 = 10
    case Sec30 = 30
    
    var id: Int { self.rawValue }
    
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
    @Published var menuText = ""
    
    var currentIcon: NSImage {
        return MenuBarIconGenerator.generateIcon(text: menuText)
    }
    
    private var timer: Timer?
    private var primaryInterface: String?
    private var netTrafficStat = NetTrafficStatReceiver()
    
    private var uploadSpeed: Double = 0.0
    private var downloadSpeed: Double = 0.0
    private var uploadMetric: String = " B"
    private var downloadMetric: String = " B"
    private let speedMetrics: [String] = [" B", "KB", "MB", "GB", "TB"]
    
    private func updateNetSpeedUpdateIntervalStatus() {
        logger.info("netSpeedUpdateInterval, \(self.netSpeedUpdateInterval.displayName)")
        self.stopTimer()
        self.startTimer()
    }
    
    private func findPrimaryInterface() -> String? {
        let storeRef = SCDynamicStoreCreate(nil, "FindCurrentInterfaceIpMac" as CFString, nil, nil)
        let global = SCDynamicStoreCopyValue(storeRef, "State:/Network/Global/IPv4" as CFString)
        let primaryInterface = global?.value(forKey: "PrimaryInterface") as? String
        return primaryInterface
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.netSpeedUpdateInterval.rawValue), repeats: true) { _ in

                self.primaryInterface = self.findPrimaryInterface()
                if (self.primaryInterface == nil) { return }
                
                if let netTrafficStatMap = self.netTrafficStat.getNetTrafficStatMap() {
                    if let netTrafficStat = netTrafficStatMap.object(forKey: self.primaryInterface!) as? NetTrafficStatOC  {
                        self.downloadSpeed = netTrafficStat.ibytes_per_sec as! Double
                        self.uploadSpeed = netTrafficStat.obytes_per_sec as! Double
                        self.downloadMetric = self.speedMetrics.first!
                        self.uploadMetric = self.speedMetrics.first!
                        for metric in self.speedMetrics.dropFirst() {
                            if self.downloadSpeed > 1000.0 {
                                self.downloadSpeed /= 1024.0
                                self.downloadMetric = metric
                            }
                            if self.uploadSpeed > 1000.0 {
                                self.uploadSpeed /= 1024.0
                                self.uploadMetric = metric
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

						let length = stringLength(max(self.downloadSpeed, self.uploadSpeed))
						self.menuText = "\(String(format: "%5.\(length.decimal)lf", self.uploadSpeed)) \(self.uploadMetric)/s\n\(String(format: "%5.\(length.decimal)lf", self.downloadSpeed)) \(self.downloadMetric)/s"

                        logger.info("deltaIn: \(String(format:"%.6f", self.downloadSpeed)) \(self.downloadMetric)/s, deltaOut: \(String(format:"%.6f", self.uploadSpeed)) \(self.uploadMetric)/s")
                    }
                }
            }
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
        logger.info("startTimer")
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
        logger.info("stopTimer")
    }
    
    init() {
        DispatchQueue.main.async {
            self.startTimer()
        }
    }
    
    deinit {
        DispatchQueue.main.async {
            self.stopTimer()
        }
    }
}

