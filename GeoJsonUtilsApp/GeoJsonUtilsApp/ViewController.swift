//
//  ViewController.swift
//  GeoJsonUtilsApp
//
//  Created by Manuel S. Gomez on 1/24/19.
//  Copyright © 2019 codingManu. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    let newYorkViewRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(40.700, -73.983),
                                        latitudinalMeters: 15000,
                                        longitudinalMeters: 15000)

    let floridaViewRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(28.2, -83.5),
                                               latitudinalMeters: 800000,
                                               longitudinalMeters: 800000)

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.mapType = MKMapType.mutedStandard
        mapView.showsScale = true
        mapView.setRegion(newYorkViewRegion, animated: true)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnMap(_:)))
        mapView.addGestureRecognizer(tap)
    }

    func resetMap() {

        let mapAnnotations = self.mapView.annotations
        let mapOverlays = self.mapView.overlays

        DispatchQueue.main.async { [unowned self] in
            self.mapView.removeOverlays(mapOverlays)
            self.mapView.removeAnnotations(mapAnnotations)
        }
    }

    func setFloridaRegion() {
        mapView.setRegion(floridaViewRegion, animated: true)
    }

    func setNewYorkRegion() {
        mapView.setRegion(newYorkViewRegion, animated: true)
    }
}

// MARK: - Actions
extension ViewController {

    @IBAction func resetMapButtonTapped(_ sender: Any) {
        resetMap()
    }

    @IBAction func loadInsideOutsidePointsButtonTapped(_ sender: Any) {
        resetMap()
        setNewYorkRegion()

        let alert = UIAlertController(title: "Check",
                                      message: "Tap the pins to check if they're inside or outside the polygon.",
                                      preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        self.present(alert, animated: true, completion: nil)

        let bundlefile = Bundle.main.url(forResource: "polygon", withExtension: "geojson")!
        let data = try? Data(contentsOf: bundlefile)

        let decoder = JSONDecoder()
        let decodedData = try? decoder.decode(GJPolygon.self, from: data!)

        guard let polygon = decodedData else { return }

        let mkPoly = polygon.asMKPolygon()
        mapView.addOverlay(mkPoly)

        let pt1 = GJPoint([-73.99643342179832, 40.63328912259067])
        let pt2 = GJPoint([-74.01643342179832, 40.63328912259067])

        let points = [pt1, pt2]
        mapView.loadGJPointsAsAnnotations(points)
    }

    @IBAction func loadNYCNeighborhoodsButtonTapped(_ sender: Any) {
        resetMap()
        setNewYorkRegion()

        // swiftlint:disable line_length
        GeoJsonUtils.readGJFeatureCollectionFromFileInBundle(file: "nyc_neighborhoods", withExtension: "geojson") { [unowned self] (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let featureCollection):
                for feature in featureCollection.features {
                    try? feature.updateTitleFromProperty(forKey: "ntaname")
                }
                self.mapView.loadGJFeatureCollection(featureCollection)
            }
        }
    }

    @IBAction func loadFloridaTrailButtonTapped(_ sender: Any) {
        resetMap()
        setFloridaRegion()

        GeoJsonUtils.readGJFeatureCollectionFromFileInBundle(file: "trail", withExtension: "geojson") { [unowned self] (result) in

            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let featureCollection):
                for feature in featureCollection.features {
                    try? feature.updateTitleFromProperty(forKey: "Trail_Name")
                }

                self.mapView.loadGJFeatureCollection(featureCollection)
            }
        }
    }

    @IBAction func twitterButtonTapped(_ sender: Any) {

        let screenName =  "codingmanu"
        let appURL = URL(string: "twitter://user?screen_name=\(screenName)")!
        let webURL = URL(string: "https://twitter.com/\(screenName)")!

        let application = UIApplication.shared

        if application.canOpenURL(appURL) {
            application.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Renderer customization & touch detection
extension ViewController {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        //Return an `MKPolylineRenderer` for the `MKPolyline` in the `MKMapViewDelegate`s method
        if let polyLine = overlay as? MKPolyline {
            let testlineRenderer = MKPolylineRenderer(polyline: polyLine)

            testlineRenderer.strokeColor = .red
            testlineRenderer.lineWidth = 2.0
            return testlineRenderer
        }

        if let polygon = overlay as? MKPolygon {
            let testPolygonRenderer = MKPolygonRenderer(polygon: polygon)

            testPolygonRenderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
            testPolygonRenderer.strokeColor = .blue
            testPolygonRenderer.lineWidth = 1.0
            return testPolygonRenderer
        }
        fatalError("Other overlay types found...")
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        guard let polygon = mapView.overlays[0] as? MKPolygon else { return }

        if polygon.containsCoordinate(view.annotation!.coordinate) {
            let alert = UIAlertController(title: "Inside",
                                          message: "Selected point is inside polygon.",
                                          preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            self.present(alert, animated: true, completion: {
                mapView.deselectAnnotation(view.annotation, animated: true)
            })

        } else {
            let alert = UIAlertController(title: "Outside",
                                          message: "Selected point is outside polygon.",
                                          preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            self.present(alert, animated: true, completion: {
                mapView.deselectAnnotation(view.annotation, animated: true)
            })
        }
    }

    @objc func didTapOnMap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        let rect = mapView.squareAroundCoordinate(coordinate, withScaleFactor: 0.15)

        if mapView.annotations(in: rect).count == 0 {
            let polygons: [MKPolygon] = mapView.overlays.filter { (overlay) -> Bool in
                    overlay is MKPolygon
                } as! [MKPolygon]
            // swiftlint:disable:previous force_cast

            for polygon in polygons {
                if polygon.containsCoordinate(coordinate) {
                    if polygon.title != nil {
                        let alert = UIAlertController(title: "Neighborhood",
                                                      message: "\n\(polygon.title!)\n",
                            preferredStyle: UIAlertController.Style.alert)

                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
