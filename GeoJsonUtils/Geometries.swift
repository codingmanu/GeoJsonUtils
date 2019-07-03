//
//  Geometries.swift
//  SwiftCityJSONTest
//
//  Created by Manuel S. Gomez on 12/23/18.
//  Copyright © 2018 codingManu. All rights reserved.
//

import Foundation
import MapKit

// MARK: - Enums for type, error & coding keys
enum GJGeometryType: String, Decodable {

    case point = "Point"
    case lineString = "LineString"
    case polygon = "Polygon"
    case multiPoint = "MultiPoint"
    case multiLineString = "MultiLineString"
    case multiPolygon = "MultiPolygon"
}

enum GJGeometryError: Error {
    case invalidType
    case invalidGeometry
    case indalidId
}

enum GJGeometryCodingKeys: String, CodingKey {
    case type
    case coordinates
}

// MARK: - Models
class GJPoint: Decodable {
    var type: GJGeometryType = .point
    var coordinates: [Double]

    init(_ coordinates: [Double]) {
        self.coordinates = coordinates
    }
}

class GJLineString: Decodable {
    var type: GJGeometryType = .lineString
    var coordinates: [[Double]]

    init(_ coordinates: [[Double]]) {
        self.coordinates = coordinates
    }
}

class GJPolygon: Decodable {
    var type: GJGeometryType = .polygon
    var coordinates: [[[Double]]]

    init(_ coordinates: [[[Double]]]) {
        self.coordinates = coordinates
    }
}

class GJMultiPolygon: Decodable {
    var type: GJGeometryType = .multiPolygon
    var coordinates: [[[[Double]]]]

    init(_ coordinates: [[[[Double]]]]) {
        self.coordinates = coordinates
    }
}

// MARK: - Conversion Extensions
extension GJPoint {

    private func asCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        let lat = coordinates[1]
        let lon = coordinates[0]

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func asMKPointAnnotation() -> MKPointAnnotation {
        let anno = MKPointAnnotation()
        anno.coordinate = self.asCLLocationCoordinate2D()
        return anno
    }
}

extension GJLineString {

    private func getPoints() -> [GJPoint] {
        let points = coordinates.map { (coordinate) -> GJPoint in
            return GJPoint(coordinate)
        }
        return points
    }

    func asMKPolyLine() -> MKPolyline {

        let coords = self.getPoints().compactMap({ (point) -> CLLocationCoordinate2D in
            return point.asMKPointAnnotation().coordinate
        })

        return MKPolyline(coordinates: coords, count: coords.count)
    }
}

extension GJPolygon {

    private func getOuterRing() -> GJLineString {
        return GJLineString(coordinates[0])
    }

    private func getInnerRings() -> [GJLineString] {
        var innerRings: [GJLineString] = []
        if coordinates.count > 1 {
            for ring in coordinates[1...] {
                innerRings.append(GJLineString(ring))
            }
        }
        return innerRings
    }

    func asMKPolygon() -> MKPolygon {
        var outerPolygonPoints = [CLLocationCoordinate2D]()

        let outerRing = self.getOuterRing()
        for point in UnsafeBufferPointer(start: outerRing.asMKPolyLine().points(),
                                         count: outerRing.asMKPolyLine().pointCount) {
                                            outerPolygonPoints.append(point.coordinate)
        }

        var innerPolygons = [MKPolygon]()

        let innerRings = self.getInnerRings()
        if innerRings.count > 0 {
            for innerRing in innerRings {
                var innerPolygonPoints = [CLLocationCoordinate2D]()
                for point in UnsafeBufferPointer(start: innerRing.asMKPolyLine().points(),
                                                 count: innerRing.asMKPolyLine().pointCount) {
                                                    innerPolygonPoints.append(point.coordinate)
                }

                innerPolygons.append(MKPolygon(coordinates: innerPolygonPoints, count: innerPolygonPoints.count))
            }
        }

        let mkPoly = MKPolygon(coordinates: outerPolygonPoints,
                               count: outerPolygonPoints.count,
                               interiorPolygons: innerPolygons)

        return mkPoly
    }
}

extension GJMultiPolygon {

    func getPolygons() -> [GJPolygon] {
        let polygons = coordinates.map { (coordinate) -> GJPolygon in
            return GJPolygon(coordinate)
        }
        return polygons
    }
}
