//
//  ContentView.swift
//  closetscanner
//
//  Created by Nimse, Akshay Bhagwat on 7/16/26.
//

import SwiftUI

#if os(iOS) && canImport(RoomPlan)
import Observation
import UIKit
@preconcurrency import RoomPlan
import simd

struct ContentView: View {
    @State private var scanner = ClosetCaptureController()

    var body: some View {
        Group {
            if !scanner.isCaptureSupported {
                UnsupportedDeviceView()
            } else if scanner.isScanning {
                ClosetScannerView(scanner: scanner)
            } else if let summary = scanner.summary {
                ClosetResultsView(summary: summary, scanner: scanner)
            } else {
                ScanStartView(scanner: scanner)
            }
        }
        .animation(.snappy, value: scanner.isScanning)
        .animation(.snappy, value: scanner.summary?.id)
    }
}

private struct ScanStartView: View {
    let scanner: ClosetCaptureController

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 10) {
                Label("ClosetScanner", systemImage: "camera.metering.matrix")
                    .font(.system(.title2, design: .rounded, weight: .semibold))

                Text("Scan a closet with RoomPlan, hide detected contents, and verify the measured empty-space dimensions against a tape-measured reference.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 14) {
                CapabilityRow(icon: "viewfinder", title: "Live iPhone scan", value: "Camera, motion tracking, and LiDAR-backed geometry")
                CapabilityRow(icon: "eye.slash", title: "Clean model", value: "Walls, doors, windows, openings, and floor plan without object boxes")
                CapabilityRow(icon: "ruler", title: "Dimensions", value: "Displayed to the nearest 1/16 in with reference-error validation")
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

            if let errorMessage = scanner.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 24)

            Button {
                scanner.prepareForScan()
            } label: {
                Label("Start Closet Scan", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct ClosetScannerView: View {
    let scanner: ClosetCaptureController

    var body: some View {
        ZStack {
            RoomCaptureContainer(scanner: scanner)
                .ignoresSafeArea()
                .onAppear {
                    scanner.startSessionIfNeeded()
                }

            VStack(spacing: 0) {
                ScannerStatusBar(status: scanner.statusText)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 12) {
                    Text(scanner.scanHint)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)

                    HStack(spacing: 12) {
                        Button(role: .cancel) {
                            scanner.cancelSession()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            scanner.stopSession()
                        } label: {
                            Label("Finish Scan", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .controlSize(.large)
                }
                .padding(16)
                .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 8))
                .padding(16)
            }
        }
    }
}

private struct ScannerStatusBar: View {
    let status: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .symbolEffect(.variableColor.iterative, options: .repeating)
            Text(status)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Spacer(minLength: 8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ClosetResultsView: View {
    let summary: ClosetScanSummary
    let scanner: ClosetCaptureController
    @State private var showHiddenObjects = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Empty Closet Model")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                        Text(summary.timestampText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        scanner.prepareForScan()
                    } label: {
                        Label("Rescan", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }

                DimensionGrid(dimensions: summary.dimensions)

                Toggle(isOn: $showHiddenObjects.animation(.snappy)) {
                    Label(showHiddenObjects ? "Detected contents visible" : "Detected contents hidden", systemImage: showHiddenObjects ? "shippingbox" : "eye.slash")
                        .font(.headline)
                }
                .toggleStyle(.switch)
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                EmptyClosetPlanView(summary: summary, showHiddenObjects: showHiddenObjects)
                    .frame(height: 320)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                ScanFactsView(summary: summary)

                AccuracyValidationView(summary: summary)

                LimitationsView()
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct DimensionGrid: View {
    let dimensions: ClosetDimensions

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            DimensionTile(label: "Width", value: dimensions.width.displayText, detail: dimensions.width.decimalInchesText, icon: "arrow.left.and.right")
            DimensionTile(label: "Depth", value: dimensions.depth.displayText, detail: dimensions.depth.decimalInchesText, icon: "arrow.up.and.down")
            DimensionTile(label: "Height", value: dimensions.height.displayText, detail: dimensions.height.decimalInchesText, icon: "arrow.up.to.line")
            DimensionTile(label: "Floor Area", value: dimensions.floorAreaText, detail: dimensions.volumeText, icon: "square.dashed")
        }
    }
}

private struct DimensionTile: View {
    let label: String
    let value: String
    let detail: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.teal)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyClosetPlanView: View {
    let summary: ClosetScanSummary
    let showHiddenObjects: Bool

    var body: some View {
        Canvas { context, size in
            guard let mapper = PlanMapper(points: summary.planPoints(includeObjects: showHiddenObjects), size: size) else {
                return
            }

            drawGrid(context: context, size: size)

            if showHiddenObjects {
                for box in summary.objectBoxes {
                    var objectPath = Path()
                    let mappedCorners = box.corners.map { mapper.map($0) }
                    guard let first = mappedCorners.first else { continue }
                    objectPath.move(to: first)
                    for corner in mappedCorners.dropFirst() {
                        objectPath.addLine(to: corner)
                    }
                    objectPath.closeSubpath()
                    context.fill(objectPath, with: .color(.orange.opacity(0.22)))
                    context.stroke(objectPath, with: .color(.orange), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }

            var wallPath = Path()
            for segment in summary.wallSegments {
                wallPath.move(to: mapper.map(segment.start))
                wallPath.addLine(to: mapper.map(segment.end))
            }
            context.stroke(wallPath, with: .color(.primary), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

            var openingPath = Path()
            for segment in summary.openingSegments {
                openingPath.move(to: mapper.map(segment.start))
                openingPath.addLine(to: mapper.map(segment.end))
            }
            context.stroke(openingPath, with: .color(.teal), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 5]))
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 12) {
                PlanLegend(color: .primary, label: "Walls")
                PlanLegend(color: .teal, label: "Openings")
                if showHiddenObjects {
                    PlanLegend(color: .orange, label: "Hidden contents")
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(12)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(showHiddenObjects ? "\(summary.objectCount) detected object boxes" : "\(summary.objectCount) object boxes hidden")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(12)
        }
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 32
        var gridPath = Path()

        var x: CGFloat = 0
        while x <= size.width {
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }

        var y: CGFloat = 0
        while y <= size.height {
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.stroke(gridPath, with: .color(.secondary.opacity(0.12)), lineWidth: 1)
    }
}

private struct PlanLegend: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.medium))
        }
    }
}

private struct ScanFactsView: View {
    let summary: ClosetScanSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Scan Output", systemImage: "doc.text.magnifyingglass")
                .font(.headline)

            FactRow(label: "Structural surfaces", value: "\(summary.wallCount) walls, \(summary.openingCount) openings")
            FactRow(label: "Contents hidden", value: "\(summary.objectCount) RoomPlan object boxes")
            FactRow(label: "Model basis", value: "RoomPlan parametric surfaces; objects omitted from clean plan")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct AccuracyValidationView: View {
    let summary: ClosetScanSummary
    @State private var selectedDimension: DimensionKind = .width
    @State private var referenceInches = ""

    private var scannedInches: Double {
        summary.dimensions.value(for: selectedDimension).roundedInches
    }

    private var referenceValue: Double? {
        Double(referenceInches.replacingOccurrences(of: ",", with: "."))
    }

    private var errorText: String {
        guard let referenceValue else { return "Enter a reference" }
        let error = abs(scannedInches - referenceValue)
        return String(format: "%.3f in error", error)
    }

    private var isWithinTarget: Bool {
        guard let referenceValue else { return false }
        return abs(scannedInches - referenceValue) <= MeasurementValue.sixteenthInch
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Accuracy Validation", systemImage: "checkmark.seal")
                .font(.headline)

            Picker("Dimension", selection: $selectedDimension) {
                ForEach(DimensionKind.allCases) { dimension in
                    Text(dimension.title).tag(dimension)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                TextField("Reference inches", text: $referenceInches)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                ValidationBadge(isWithinTarget: isWithinTarget, hasReference: referenceValue != nil)
            }

            FactRow(label: "Scanned", value: String(format: "%.3f in", scannedInches))
            FactRow(label: "Target", value: "+/- 0.0625 in")
            FactRow(label: "Result", value: errorText)

            Text("Validation protocol: measure the same interior span with a steel tape or laser tape, run at least three scans, and report max absolute error per axis. Treat 1/16 in as the acceptance target, not as a sensor guarantee.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ValidationBadge: View {
    let isWithinTarget: Bool
    let hasReference: Bool

    var body: some View {
        Label(hasReference ? (isWithinTarget ? "Pass" : "Review") : "Pending", systemImage: hasReference ? (isWithinTarget ? "checkmark.circle.fill" : "exclamationmark.circle.fill") : "circle")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(hasReference ? (isWithinTarget ? .green : .orange) : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background((hasReference ? (isWithinTarget ? Color.green : Color.orange) : Color.secondary).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LimitationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Limitations", systemImage: "exclamationmark.triangle")
                .font(.headline)

            Text("RoomPlan works best on LiDAR-capable iPhones with good light, visible wall edges, slow motion, and minimal reflective or transparent surfaces. The clean model hides recognized object boxes in the generated representation; it does not photorealistically inpaint the live camera feed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CapabilityRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(.teal)
                .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct FactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("RoomPlan unavailable", systemImage: "iphone.slash")
                .font(.system(.title2, design: .rounded, weight: .semibold))

            Text("Run this demo on a LiDAR-capable iPhone or iPad. The Simulator and non-LiDAR devices cannot produce the closet scan required for the live presentation.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color(.systemGroupedBackground))
    }
}

private struct RoomCaptureContainer: UIViewRepresentable {
    let scanner: ClosetCaptureController

    func makeUIView(context: Context) -> RoomCaptureView {
        scanner.captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
    }
}

@MainActor
@Observable
@objc(ClosetCaptureController)
private final class ClosetCaptureController: NSObject, NSCoding {
    let captureView: RoomCaptureView

    private(set) var isScanning = false
    private(set) var summary: ClosetScanSummary?
    private(set) var statusText = "Ready"
    private(set) var errorMessage: String?

    private var isSessionRunning = false

    var isCaptureSupported: Bool {
        RoomCaptureSession.isSupported
    }

    var scanHint: String {
        "Move slowly across the closet opening, include the back wall, floor, side walls, and ceiling line, then finish when the structural outline stabilizes."
    }

    override init() {
        captureView = RoomCaptureView(frame: .zero)
        super.init()
        captureView.delegate = self
    }

    required init?(coder: NSCoder) {
        captureView = RoomCaptureView(frame: .zero)
        super.init()
        captureView.delegate = self
    }

    func encode(with coder: NSCoder) {
    }

    func prepareForScan() {
        guard isCaptureSupported else {
            errorMessage = "RoomPlan requires a supported LiDAR device."
            return
        }

        errorMessage = nil
        summary = nil
        statusText = "Move device to start"
        isScanning = true
    }

    func startSessionIfNeeded() {
        guard !isSessionRunning else { return }

        var configuration = RoomCaptureSession.Configuration()
        configuration.isCoachingEnabled = true
        captureView.captureSession.run(configuration: configuration)
        isSessionRunning = true
        statusText = "Scanning closet geometry"
    }

    func stopSession() {
        guard isSessionRunning else {
            isScanning = false
            return
        }

        statusText = "Processing clean model"
        captureView.captureSession.stop()
        isSessionRunning = false
    }

    func cancelSession() {
        if isSessionRunning {
            captureView.captureSession.stop()
            isSessionRunning = false
        }

        statusText = "Ready"
        isScanning = false
    }
}

extension ClosetCaptureController: RoomCaptureViewDelegate {
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error {
            errorMessage = error.localizedDescription
            statusText = "Scan failed"
            isScanning = false
            return false
        }

        statusText = "Building RoomPlan result"
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error {
            errorMessage = error.localizedDescription
            statusText = "Scan failed"
            isScanning = false
            return
        }

        summary = ClosetScanSummary(room: processedResult)
        statusText = "Scan complete"
        isScanning = false
    }
}

private struct ClosetScanSummary: Identifiable, Equatable {
    let id = UUID()
    let capturedAt = Date()
    let dimensions: ClosetDimensions
    let wallSegments: [PlanSegment]
    let openingSegments: [PlanSegment]
    let objectBoxes: [PlanBox]
    let wallCount: Int
    let openingCount: Int
    let objectCount: Int

    var timestampText: String {
        capturedAt.formatted(date: .abbreviated, time: .shortened)
    }

    @MainActor
    init(room: CapturedRoom) {
        wallSegments = room.walls.compactMap { PlanSegment(surface: $0, kind: .wall) }
        openingSegments = (room.doors + room.openings + room.windows).compactMap { PlanSegment(surface: $0, kind: .opening) }
        objectBoxes = room.objects.compactMap(PlanBox.init(object:))
        wallCount = room.walls.count
        openingCount = room.doors.count + room.openings.count + room.windows.count
        objectCount = room.objects.count
        dimensions = ClosetDimensions(room: room, wallSegments: wallSegments)
    }

    func planPoints(includeObjects: Bool) -> [CGPoint] {
        var points = (wallSegments + openingSegments).flatMap { [$0.start, $0.end] }

        if includeObjects {
            points += objectBoxes.flatMap(\.corners)
        }

        if points.isEmpty {
            points = [
                .zero,
                CGPoint(x: max(dimensions.width.meters, 0.5), y: max(dimensions.depth.meters, 0.5))
            ]
        }

        return points
    }
}

private struct ClosetDimensions: Equatable {
    let width: MeasurementValue
    let depth: MeasurementValue
    let height: MeasurementValue

    var floorAreaText: String {
        let squareFeet = width.meters * depth.meters * 10.7639104167
        return String(format: "%.2f sq ft", squareFeet)
    }

    var volumeText: String {
        let cubicFeet = width.meters * depth.meters * height.meters * 35.3146667215
        return String(format: "%.1f cu ft", cubicFeet)
    }

    init(room: CapturedRoom, wallSegments: [PlanSegment]) {
        let structuralPoints = wallSegments.flatMap { [$0.start, $0.end] }
        let horizontalBounds = OrientedPlanBounds(points: structuralPoints)

        let floorFallback = room.floors
            .map { (Double($0.dimensions.x), Double(max($0.dimensions.z, $0.dimensions.y))) }
            .max { lhs, rhs in
                lhs.0 * lhs.1 < rhs.0 * rhs.1
            }

        let measuredWidth = horizontalBounds?.longSide ?? floorFallback?.0 ?? 0
        let measuredDepth = horizontalBounds?.shortSide ?? floorFallback?.1 ?? 0
        let measuredHeight = room.walls.map { Double($0.dimensions.y) }.max() ?? 0

        width = MeasurementValue(meters: measuredWidth)
        depth = MeasurementValue(meters: measuredDepth)
        height = MeasurementValue(meters: measuredHeight)
    }

    func value(for dimension: DimensionKind) -> MeasurementValue {
        switch dimension {
        case .width:
            width
        case .depth:
            depth
        case .height:
            height
        }
    }
}

private struct MeasurementValue: Equatable {
    static let metersToInches = 39.37007874015748
    static let sixteenthInch = 1.0 / 16.0

    let meters: Double

    var roundedInches: Double {
        (meters * Self.metersToInches * 16).rounded() / 16
    }

    var displayText: String {
        Self.feetAndInchesText(for: roundedInches)
    }

    var decimalInchesText: String {
        String(format: "%.3f in", roundedInches)
    }

    private static func feetAndInchesText(for inches: Double) -> String {
        guard inches.isFinite, inches > 0 else { return "No data" }

        var totalSixteenths = Int((inches * 16).rounded())
        let feet = totalSixteenths / (12 * 16)
        totalSixteenths -= feet * 12 * 16

        let wholeInches = totalSixteenths / 16
        let fraction = totalSixteenths % 16

        var parts: [String] = []
        if feet > 0 {
            parts.append("\(feet) ft")
        }

        if fraction == 0 {
            parts.append("\(wholeInches) in")
        } else {
            let divisor = greatestCommonDivisor(fraction, 16)
            let numerator = fraction / divisor
            let denominator = 16 / divisor
            parts.append("\(wholeInches) \(numerator)/\(denominator) in")
        }

        return parts.joined(separator: " ")
    }

    private static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var x = a
        var y = b
        while y != 0 {
            let remainder = x % y
            x = y
            y = remainder
        }
        return max(x, 1)
    }
}

private enum DimensionKind: String, CaseIterable, Identifiable {
    case width
    case depth
    case height

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private struct PlanSegment: Identifiable, Equatable {
    enum Kind: Equatable {
        case wall
        case opening
    }

    let id = UUID()
    let start: CGPoint
    let end: CGPoint
    let kind: Kind

    init?(surface: CapturedRoom.Surface, kind: Kind) {
        let length = max(surface.dimensions.x, surface.dimensions.z)
        guard length > 0 else { return nil }

        let halfLength = length / 2
        let localStart = SIMD3<Float>(-halfLength, 0, 0)
        let localEnd = SIMD3<Float>(halfLength, 0, 0)
        let worldStart = surface.transform.transformPoint(localStart)
        let worldEnd = surface.transform.transformPoint(localEnd)

        start = CGPoint(x: CGFloat(worldStart.x), y: CGFloat(worldStart.z))
        end = CGPoint(x: CGFloat(worldEnd.x), y: CGFloat(worldEnd.z))
        self.kind = kind
    }
}

private struct PlanBox: Identifiable, Equatable {
    let id = UUID()
    let corners: [CGPoint]

    init?(object: CapturedRoom.Object) {
        let halfWidth = object.dimensions.x / 2
        let halfDepth = object.dimensions.z / 2
        guard halfWidth > 0, halfDepth > 0 else { return nil }

        let localCorners = [
            SIMD3<Float>(-halfWidth, 0, -halfDepth),
            SIMD3<Float>(halfWidth, 0, -halfDepth),
            SIMD3<Float>(halfWidth, 0, halfDepth),
            SIMD3<Float>(-halfWidth, 0, halfDepth)
        ]

        corners = localCorners.map {
            let point = object.transform.transformPoint($0)
            return CGPoint(x: CGFloat(point.x), y: CGFloat(point.z))
        }
    }
}

private struct OrientedPlanBounds {
    let longSide: Double
    let shortSide: Double

    init?(points: [CGPoint]) {
        guard points.count >= 2 else { return nil }

        let meanX = points.map(\.x).reduce(0, +) / CGFloat(points.count)
        let meanY = points.map(\.y).reduce(0, +) / CGFloat(points.count)

        var covarianceXX: CGFloat = 0
        var covarianceXY: CGFloat = 0
        var covarianceYY: CGFloat = 0

        for point in points {
            let dx = point.x - meanX
            let dy = point.y - meanY
            covarianceXX += dx * dx
            covarianceXY += dx * dy
            covarianceYY += dy * dy
        }

        let angle = 0.5 * atan2(2 * covarianceXY, covarianceXX - covarianceYY)
        let primary = CGVector(dx: cos(angle), dy: sin(angle))
        let secondary = CGVector(dx: -primary.dy, dy: primary.dx)

        let primaryProjections = points.map { $0.x * primary.dx + $0.y * primary.dy }
        let secondaryProjections = points.map { $0.x * secondary.dx + $0.y * secondary.dy }

        guard
            let minPrimary = primaryProjections.min(),
            let maxPrimary = primaryProjections.max(),
            let minSecondary = secondaryProjections.min(),
            let maxSecondary = secondaryProjections.max()
        else {
            return nil
        }

        let sideA = Double(maxPrimary - minPrimary)
        let sideB = Double(maxSecondary - minSecondary)
        longSide = max(sideA, sideB)
        shortSide = min(sideA, sideB)
    }
}

private struct PlanMapper {
    private let minX: CGFloat
    private let minY: CGFloat
    private let scale: CGFloat
    private let xOffset: CGFloat
    private let yOffset: CGFloat
    private let contentHeight: CGFloat

    init?(points: [CGPoint], size: CGSize) {
        guard
            let minX = points.map(\.x).min(),
            let maxX = points.map(\.x).max(),
            let minY = points.map(\.y).min(),
            let maxY = points.map(\.y).max()
        else {
            return nil
        }

        let padding: CGFloat = 30
        let contentWidth = max(maxX - minX, 0.25)
        let contentHeight = max(maxY - minY, 0.25)
        let availableWidth = max(size.width - padding * 2, 1)
        let availableHeight = max(size.height - padding * 2, 1)
        let scale = min(availableWidth / contentWidth, availableHeight / contentHeight)
        let renderedWidth = contentWidth * scale
        let renderedHeight = contentHeight * scale

        self.minX = minX
        self.minY = minY
        self.scale = scale
        self.xOffset = (size.width - renderedWidth) / 2
        self.yOffset = (size.height - renderedHeight) / 2
        self.contentHeight = contentHeight
    }

    func map(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: xOffset + (point.x - minX) * scale,
            y: yOffset + (contentHeight - (point.y - minY)) * scale
        )
    }
}

private extension simd_float4x4 {
    func transformPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
        let result = self * SIMD4<Float>(point.x, point.y, point.z, 1)
        return SIMD3<Float>(result.x, result.y, result.z)
    }
}

#else

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("ClosetScanner requires iPhone", systemImage: "iphone.slash")
                .font(.title2.weight(.semibold))

            Text("Build and run the app on a LiDAR-capable iPhone or iPad to use RoomPlan closet scanning.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

#endif

#Preview {
    ContentView()
}
