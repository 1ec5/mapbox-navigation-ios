#import <Mapbox/Mapbox.h>

@interface MGLMapView (MGLNavigationAdditions) <CLLocationManagerDelegate>

// FIXME: This will be removed once https://github.com/mapbox/mapbox-gl-native/issues/6867 is implemented
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations;

// FIXME: This will be removed once https://github.com/mapbox/mapbox-navigation-ios/issues/352 is implemented.
- (void)validateLocationServices;

- (void)_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                 edgePadding:(UIEdgeInsets)insets
                   zoomLevel:(double)zoomLevel
                   direction:(CLLocationDirection)direction
                    duration:(NSTimeInterval)duration
     animationTimingFunction:(nullable CAMediaTimingFunction *)function
           completionHandler:(nullable void (^)(void))completion;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                edgePadding:(UIEdgeInsets)edgePadding
                  zoomLevel:(double)zoomLevel
                  direction:(CLLocationDirection)direction;

- (void)mapViewDidFinishRenderingFrameFullyRendered:(BOOL)fullyRendered;

@property (nonatomic, readonly) CLLocationManager *locationManager;

@end
