import SwiftUI
import CoreLocation

struct CompassView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Binding var target: CLLocationCoordinate2D?
    @Binding var targetName: String

    // Bearing from user's location to the target (degrees, clockwise from North)
    private var targetBearing: Double {
        guard let userCoord = locationManager.location?.coordinate,
              let dest = target else { return 0 }
        return userCoord.bearing(to: dest)
    }

    // How many degrees to rotate the whole compass rose so that North stays visually correct
    private var compassRoseRotation: Double {
        -(locationManager.heading?.magneticHeading ?? 0)
    }

    // Angle of the target needle relative to screen top
    private var targetNeedleRotation: Double {
        targetBearing + compassRoseRotation
    }

    private var distanceText: String? {
        guard let userLoc = locationManager.location, let dest = target else { return nil }
        let meters = userLoc.distance(from: CLLocation(latitude: dest.latitude, longitude: dest.longitude))
        if meters >= 1_000_000 {
            return String(format: "%.0f,000 km", meters / 1_000_000)
        } else if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Target info banner
                Group {
                    if target != nil {
                        VStack(spacing: 6) {
                            Text(targetName.isEmpty ? "Custom Pin" : targetName)
                                .font(.title2.weight(.semibold))
                            if let dist = distanceText {
                                Label(dist, systemImage: "location.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(bearingLabel(targetBearing))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("Pin a target on the Map tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                    }
                }

                // Compass
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(.systemGray4), Color(.systemGray2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 300, height: 300)
                        .shadow(color: .black.opacity(0.15), radius: 10)

                    // Compass rose (rotates with device heading)
                    CompassRose()
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(compassRoseRotation))
                        .animation(.easeInOut(duration: 0.15), value: compassRoseRotation)

                    // North needle (always pointing to magnetic north)
                    CompassNeedle(northColor: .red, southColor: .white)
                        .frame(width: 24, height: 220)
                        .rotationEffect(.degrees(compassRoseRotation))
                        .animation(.easeInOut(duration: 0.15), value: compassRoseRotation)

                    // Target needle (blue arrow pointing to destination)
                    if target != nil {
                        TargetArrow()
                            .frame(width: 30, height: 240)
                            .rotationEffect(.degrees(targetNeedleRotation))
                            .animation(.easeInOut(duration: 0.15), value: targetNeedleRotation)
                    }

                    // Center dot
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 20, height: 20)
                        .shadow(radius: 3)
                }

                // Bearing readout
                if target != nil {
                    HStack(spacing: 32) {
                        VStack {
                            Text("\(Int(targetBearing.rounded()))°")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Bearing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Divider().frame(height: 40)
                        VStack {
                            Text(String(format: "%.1f°", locationManager.heading?.magneticHeading ?? 0))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Heading")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Compass")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func bearingLabel(_ bearing: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((bearing + 22.5) / 45) % 8
        return "\(Int(bearing.rounded()))° \(directions[index])"
    }
}

// MARK: - Compass Rose Drawing

struct CompassRose: View {
    var body: some View {
        ZStack {
            // Tick marks
            ForEach(0..<72) { i in
                let angle = Double(i) * 5
                let isMajor = i % 9 == 0   // 0, 45, 90, 135 ...
                let isMinor = i % 3 == 0

                Rectangle()
                    .fill(isMajor ? Color.primary : (isMinor ? Color(.systemGray2) : Color(.systemGray4)))
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? 20 : (isMinor ? 12 : 8))
                    .offset(y: -125)
                    .rotationEffect(.degrees(angle))
            }

            // Cardinal labels
            ForEach(["N", "E", "S", "W"].indices, id: \.self) { i in
                let angle = Double(i) * 90
                Text(["N", "E", "S", "W"][i])
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(i == 0 ? .red : .primary)
                    .offset(y: -100)
                    .rotationEffect(.degrees(angle))
            }

            // Intercardinal labels
            ForEach(["NE", "SE", "SW", "NW"].indices, id: \.self) { i in
                let angle = Double(i) * 90 + 45
                Text(["NE", "SE", "SW", "NW"][i])
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .offset(y: -82)
                    .rotationEffect(.degrees(angle))
            }
        }
    }
}

// MARK: - Compass Needle (bicolor: red=North, white=South)

struct CompassNeedle: View {
    var northColor: Color = .red
    var southColor: Color = .white

    var body: some View {
        ZStack {
            // North half (top)
            Triangle()
                .fill(northColor)
                .frame(width: 24, height: 110)
                .offset(y: -55)
                .shadow(color: northColor.opacity(0.4), radius: 4)

            // South half (bottom)
            Triangle()
                .fill(southColor)
                .frame(width: 24, height: 110)
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                .offset(y: 55)
                .shadow(color: .black.opacity(0.15), radius: 4)
        }
    }
}

// MARK: - Target Direction Arrow (blue)

struct TargetArrow: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.blue.opacity(0.8))
                .frame(width: 8, height: 200)

            Image(systemName: "arrowtriangle.up.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .offset(y: -110)

            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue.opacity(0.4))
                .frame(width: 16, height: 16)
                .offset(y: 110)
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
