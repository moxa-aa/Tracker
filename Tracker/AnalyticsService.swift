import Foundation
import AppMetricaCore

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func report(event: String, screen: String, item: String? = nil) {
        var parameters: [String: Any] = ["screen": screen]
        if let item = item {
            parameters["item"] = item
        }
        AppMetrica.reportEvent(name: event, parameters: parameters, onFailure: { error in
            print("AppMetrica report event failed: \(error.localizedDescription)")
        })
    }
}
