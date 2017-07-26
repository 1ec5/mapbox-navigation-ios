import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

/**
 `NavigationViewController` is the base location manager which handles
 permissions and background modes.
 */
@objc(MBNavigationLocationManager)
open class NavigationLocationManager: CLLocationManager {
    
    var lastKnownLocation: CLLocation?
    
    /**
     Indicates whether the device is plugged in or not.
     */
    public var isPluggedIn: Bool = false
    
    override public init() {
        super.init()
        
        let always = Bundle.main.locationAlwaysUsageDescription
        let both = Bundle.main.locationAlwaysAndWhenInUseUsageDescription
        
        if always != nil || both != nil {
            requestAlwaysAuthorization()
        } else {
            requestWhenInUseAuthorization()
        }
        
        if #available(iOS 9.0, *) {
            if Bundle.main.backgroundModes.contains("location") {
                allowsBackgroundLocationUpdates = true
            }
        }
        
        #if os(iOS)
            UIDevice.current.addObserver(self, forKeyPath: "batteryState", options: .initial, context: nil)
        #endif
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "batteryState" {
            let batteryState = UIDevice.current.batteryState
            isPluggedIn = batteryState == .charging || batteryState == .full
            desiredAccuracy = isPluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        }
    }
    
    #if os(iOS)
    deinit {
        UIDevice.current.removeObserver(self, forKeyPath: "batteryState")
    }
    #endif
}
