import Polyline
import MapboxDirections
import AVFoundation
import MapboxMobileEvents

let SecondsForCollectionAfterFeedbackEvent: TimeInterval = 20

struct DefaultEventDictionary {
    var originalRequestIdentifier: String?
    var requestIdentifier: String?
    var lat: CLLocationDegrees?
    var lng: CLLocationDegrees?
    var originalGeometry: String?
    var originalEstimatedDistance: CLLocationDistance?
    var originalEstimatedDuration: TimeInterval?
    var geometry: String?
    var estimatedDistance: CLLocationDistance?
    var estimatedDuration: TimeInterval?
    var created: String
    var startTimestamp: String
    var platform: String
    var operatingSystem: String
    var device: String
    var sdkIdentifier: String
    var sdkVersion: String
    var eventVersion: Int
    var profile: String
    var simulation: Bool
    var sessionIdentifier: String
    var distanceCompleted: CLLocationDistance
    var distanceRemaining: TimeInterval
    var durationRemaining: TimeInterval
    var rerouteCount: Int
    var volumeLevel: Int
    var screenBrightness: Int
    var batteryPluggedIn: Bool
    var batteryLevel: Float
    var applicationState: String
    
    init(routeController: RouteController, session: SessionState) {
        created = Date().ISO8601
        startTimestamp = session.departureTimestamp!.ISO8601
        
        platform = ProcessInfo.systemName
        operatingSystem = "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)"
        device = UIDevice.current.machine
        
        sdkIdentifier = routeController.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        sdkVersion = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
        
        eventVersion = 2
        
        profile = routeController.routeProgress.route.routeOptions.profileIdentifier.rawValue
        simulation = routeController.locationManager is ReplayLocationManager || routeController.locationManager is SimulatedLocationManager ? true : false
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = nil
        requestIdentifier = nil
        
        if let location = routeController.locationManager.location {
            lat = location.coordinate.latitude
            lng = location.coordinate.longitude
        }
        
        if let geometry = session.originalRoute.coordinates {
            originalGeometry = Polyline(coordinates: geometry).encodedPolyline
            originalEstimatedDistance = round(session.originalRoute.distance)
            originalEstimatedDuration = round(session.originalRoute.expectedTravelTime)
        }
        if let geometry = session.currentRoute.coordinates {
            self.geometry = Polyline(coordinates: geometry).encodedPolyline
            estimatedDistance = round(session.currentRoute.distance)
            estimatedDuration = round(session.currentRoute.expectedTravelTime)
        }
        
        distanceCompleted = round(session.totalDistanceCompleted + routeController.routeProgress.distanceTraveled)
        distanceRemaining = round(routeController.routeProgress.distanceRemaining)
        durationRemaining = round(routeController.routeProgress.durationRemaining)
        
        rerouteCount = session.numberOfReroutes
        
        volumeLevel = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        screenBrightness = Int(UIScreen.main.brightness * 100)
        
        batteryPluggedIn = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        batteryLevel = UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel * 100 : -1
        applicationState = UIApplication.shared.applicationState.telemetryString
    }
    
    func convertToDictionary() -> [String: Any] {
        var modifiedEventDictionary: [String: Any] = [:]
        
        modifiedEventDictionary["created"] = created
        modifiedEventDictionary["startTimestamp"] = startTimestamp
        
        modifiedEventDictionary["platform"] = ProcessInfo.systemName
        modifiedEventDictionary["operatingSystem"] = "\(ProcessInfo.systemName) \(ProcessInfo.systemVersion)"
        modifiedEventDictionary["device"] = UIDevice.current.machine
        
        modifiedEventDictionary["sdkIdentifier"] = sdkIdentifier
        modifiedEventDictionary["sdkVersion"] = sdkVersion
        
        modifiedEventDictionary["eventVersion"] = 2
        
        modifiedEventDictionary["profile"] = profile
        modifiedEventDictionary["simulation"] = simulation
        
        modifiedEventDictionary["sessionIdentifier"] = sessionIdentifier
        modifiedEventDictionary["originalRequestIdentifier"] = originalRequestIdentifier
        modifiedEventDictionary["requestIdentifier"] = requestIdentifier
        
        modifiedEventDictionary["lat"] = lat
        modifiedEventDictionary["lng"] = lng
        
        modifiedEventDictionary["originalGeometry"] = originalGeometry
        modifiedEventDictionary["originalEstimatedDistance"] = originalEstimatedDistance
        modifiedEventDictionary["originalEstimatedDuration"] = originalEstimatedDuration
        
        modifiedEventDictionary["geometry"] = geometry
        modifiedEventDictionary["estimatedDistance"] = estimatedDistance
        modifiedEventDictionary["estimatedDuration"] = estimatedDuration
        
        modifiedEventDictionary["distanceCompleted"] = distanceCompleted
        modifiedEventDictionary["distanceRemaining"] = distanceRemaining
        modifiedEventDictionary["durationRemaining"] = durationRemaining
        
        modifiedEventDictionary["rerouteCount"] = rerouteCount
        
        modifiedEventDictionary["volumeLevel"] = volumeLevel
        modifiedEventDictionary["screenBrightness"] = screenBrightness
        
        modifiedEventDictionary["batteryPluggedIn"] = batteryPluggedIn
        modifiedEventDictionary["batteryLevel"] = batteryLevel
        modifiedEventDictionary["applicationState"] = applicationState
        
        return modifiedEventDictionary
    }
}

extension MMEEventsManager {
    func addDefaultEvents(routeController: RouteController) -> [String: Any] {
        return DefaultEventDictionary(routeController: routeController, session: routeController.sessionState).convertToDictionary()
    }
}

extension UIApplicationState {
    var telemetryString: String {
        get {
            switch self {
            case .active:
                return "Foreground"
            case .inactive:
                return "Inactive"
            case .background:
                return "Background"
            }
        }
    }
}

extension UIDevice {
    @nonobjc var machine: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            
            return identifier
        }
    }
}

extension CLLocation {
    var eventDictionary: [String: Any] {
        get {
            var locationDictionary:[String: Any] = [:]
            locationDictionary["lat"] = coordinate.latitude
            locationDictionary["lng"] = coordinate.longitude
            locationDictionary["altitude"] = altitude
            locationDictionary["timestamp"] = timestamp.ISO8601
            locationDictionary["horizontalAccuracy"] = horizontalAccuracy
            locationDictionary["verticalAccuracy"] = verticalAccuracy
            locationDictionary["course"] = course
            locationDictionary["speed"] = speed
            return locationDictionary
        }
    }
}

class FixedLengthQueue<T> {
    private var objects = Array<T>()
    private var length: Int
    
    public init(length: Int) {
        self.length = length
    }
    
    public func push(_ obj: T) {
        objects.append(obj)
        if objects.count == length {
            objects.remove(at: 0)
        }
    }
    
    public var allObjects: Array<T> {
        get {
            return Array(objects)
        }
    }
}

class CoreFeedbackEvent: Hashable {
    var id = UUID()
    
    var timestamp: Date
    
    var eventDictionary: [String: Any]
    
    init(timestamp: Date, eventDictionary: [String: Any]) {
        self.timestamp = timestamp
        self.eventDictionary = eventDictionary
    }
    
    var hashValue: Int {
        get {
            return id.hashValue
        }
    }
    
    static func ==(lhs: CoreFeedbackEvent, rhs: CoreFeedbackEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

class FeedbackEvent: CoreFeedbackEvent {}

class RerouteEvent: CoreFeedbackEvent {}
