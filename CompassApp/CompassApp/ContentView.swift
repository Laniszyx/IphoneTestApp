import SwiftUI
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var target: CLLocationCoordinate2D?
    @State private var targetName: String = ""
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CompassView(target: $target, targetName: $targetName)
                .tabItem {
                    Label("Compass", systemImage: "safari")
                }
                .tag(0)

            MapTargetView(target: $target, targetName: $targetName)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
        }
    }
}
