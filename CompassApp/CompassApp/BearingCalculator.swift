import CoreLocation

extension CLLocationCoordinate2D {
    /// Returns the bearing in degrees (0–360, clockwise from North) from this coordinate to the target.
    func bearing(to target: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude.toRadians()
        let lon1 = self.longitude.toRadians()
        let lat2 = target.latitude.toRadians()
        let lon2 = target.longitude.toRadians()

        let dLon = lon2 - lon1

        let x = sin(dLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let radians = atan2(x, y)
        return (radians.toDegrees() + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Double {
    func toRadians() -> Double { self * .pi / 180 }
    func toDegrees() -> Double { self * 180 / .pi }
}
