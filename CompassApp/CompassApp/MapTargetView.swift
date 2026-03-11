import SwiftUI
import MapKit
import CoreLocation

struct MapTargetView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Binding var target: CLLocationCoordinate2D?
    @Binding var targetName: String

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [MKMapItem] = []
    @State private var showSearchResults = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Map
                MapView(region: $region, target: $target, userLocation: locationManager.location, onTargetPinned: reverseGeocode)
                    .ignoresSafeArea(edges: .bottom)
                    .onTapGesture { /* handled inside MapView via UIViewRepresentable */ }

                    // Search bar + results
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search city, country, or address…", text: $searchText)
                            .textFieldStyle(.plain)
                            .submitLabel(.search)
                            .onSubmit { performSearch() }
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchResults = []
                                showSearchResults = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if showSearchResults && !searchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        selectSearchResult(item)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name ?? "Unknown")
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            if let placemark = item.placemark.title {
                                                Text(placemark)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                    }
                                    Divider().padding(.leading, 12)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Set Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if target != nil {
                        Button(role: .destructive) {
                            target = nil
                            targetName = ""
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .alert("Search Error", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage ?? "")
            }
            .onAppear {
                if let loc = locationManager.location {
                    region = MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
                    )
                }
            }
            .onChange(of: locationManager.location) { newLoc in
                guard target == nil, let loc = newLoc else { return }
                region = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
                )
            }
        }
    }

    // MARK: - Helpers

    private func setTarget(_ coord: CLLocationCoordinate2D, name: String) {
        target = coord
        targetName = name
    }

    private func centerOnUserLocation() {
        guard let loc = locationManager.location else { return }
        withAnimation {
            region = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        MKLocalSearch(request: request).start { response, error in
            isSearching = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            searchResults = response?.mapItems ?? []
            showSearchResults = true
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        let name = item.name ?? item.placemark.title ?? ""
        setTarget(coord, name: name)
        showSearchResults = false
        searchText = ""
        withAnimation {
            region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
            )
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first {
                let parts = [
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }
                targetName = parts.joined(separator: ", ")
            }
        }
    }
}

// MARK: - UIViewRepresentable MapView

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var target: CLLocationCoordinate2D?
    var userLocation: CLLocation?
    var onTargetPinned: ((CLLocationCoordinate2D) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update annotations
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        if let coord = target {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            mapView.addAnnotation(annotation)
        }

        // Only update region if it materially differs from the map's current region
        let delta = abs(mapView.region.center.latitude - region.center.latitude)
                  + abs(mapView.region.center.longitude - region.center.longitude)
        if delta > 0.0001 {
            mapView.setRegion(region, animated: true)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = "target"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.markerTintColor = .systemBlue
            view.glyphImage = UIImage(systemName: "mappin")
            view.canShowCallout = false
            return view
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            DispatchQueue.main.async {
                self.parent.target = coord
                self.parent.onTargetPinned?(coord)
            }
        }
    }
}

// MARK: - Region coordinate helper

extension MKCoordinateRegion {
    /// Convert a CGPoint within a view of the given size to a map coordinate.
    func coordinate(for point: CGPoint, in size: CGSize) -> CLLocationCoordinate2D {
        let latDelta = span.latitudeDelta * Double(point.y / size.height) - span.latitudeDelta / 2
        let lonDelta = span.longitudeDelta * Double(point.x / size.width) - span.longitudeDelta / 2
        return CLLocationCoordinate2D(
            latitude: center.latitude - latDelta,
            longitude: center.longitude + lonDelta
        )
    }
}
