//
//  QRCodeScannerView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import AVFoundation
import FirebaseFirestore
import SwiftUI
import Vision

struct QRCodeScannerView: View {
    @State private var scannedCode: String? = nil
    @State private var scanResult: String = "Scanning..."
    @State private var isScanning = false
    @Environment(\.presentationMode) var presentationMode
    var eventName: String
    var eventId: String

    var body: some View {
        VStack {
            Text(eventName.isEmpty ? "Scan QR Code" : "Scan QR Code for \(eventName)")
                .font(.title)
                .padding()

            // Camera preview area
            ZStack {
                if isScanning {
                    // Camera preview will be added here using UIViewRepresentable
                    QRCodeScannerCameraView(scannedCode: $scannedCode)
                        .onAppear { self.scanResult = "Scanning..." }
                } else {
                    Text("Camera Preview")
                        .foregroundColor(.gray)
                }

                // Overlay for scanning area visualization (optional but good UX)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 300, height: 370)
            }
            .frame(maxWidth: .infinity, maxHeight: 500)
            .padding()

            Text(scanResult)
                .font(.headline)
                .foregroundColor(.primary)
                .padding()

            Spacer()

            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .onAppear {
            checkCameraPermission()
        }
        .onChange(of: scannedCode) { newValue in
            if let ticketId = newValue {
                handleScannedTicket(ticketId)
            }
        }
    }

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isScanning = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.isScanning = true
                    } else {
                        self.scanResult = "Camera access denied."
                    }
                }
            }
        case .denied, .restricted:
            scanResult = "Camera access denied or restricted."
        @unknown default:
            scanResult = "Unknown camera permission status."
        }
    }

    func handleScannedTicket(_ ticketId: String) {
        self.isScanning = false
        self.scanResult = "Processing ticket..."

        let db = Firestore.firestore()
        let ticketRef = db.collection("tickets").document(ticketId)

        ticketRef.getDocument { ticketDocument, ticketError in
            if let ticketError = ticketError {
                self.scanResult = "Error fetching ticket: \(ticketError.localizedDescription)"
                self.resumeScanningAfterDelay()
                return
            }

            guard let ticketDocument = ticketDocument, ticketDocument.exists else {
                self.scanResult = "Ticket not found."
                self.resumeScanningAfterDelay()
                return
            }

            guard let ticketData = ticketDocument.data() else {
                self.scanResult = "Ticket data incomplete."
                self.resumeScanningAfterDelay()
                return
            }

            // Check ticket status
            if let status = ticketData["status"] as? String {
                if status == "used" {
                    self.scanResult = "Ticket already used."
                    self.resumeScanningAfterDelay()
                    return
                }
            }

            guard let eventId = ticketData["eventId"] as? String else {
                self.scanResult = "Ticket missing event ID."
                self.resumeScanningAfterDelay()
                return
            }

            // Fetch event details to check capacity
            let eventRef = db.collection("events").document(eventId)
            eventRef.getDocument { eventDocument, eventError in
                if let eventError = eventError {
                    self.scanResult = "Error fetching event: \(eventError.localizedDescription)"
                    self.resumeScanningAfterDelay()
                    return
                }

                guard let eventDocument = eventDocument, eventDocument.exists else {
                    self.scanResult = "Associated event not found."
                    self.resumeScanningAfterDelay()
                    return
                }

                guard let eventData = eventDocument.data(),
                      let attendees = eventData["attendees"] as? Int,
                      let maxCapacity = eventData["maxCapacity"] as? Int
                else {
                    self.scanResult = "Event data incomplete (attendees/capacity)."
                    self.resumeScanningAfterDelay()
                    return
                }

                if attendees >= maxCapacity {
                    self.scanResult = "Event is full. Max capacity reached."
                    self.resumeScanningAfterDelay()
                    return
                }

                // Mark ticket as used and increment event attendees
                ticketRef.updateData([
                    "status": "used",
                    "usedAt": Timestamp(date: Date())
                ]) { ticketUpdateErr in
                    if let ticketUpdateErr = ticketUpdateErr {
                        self.scanResult = "Error updating ticket status: \(ticketUpdateErr.localizedDescription)"
                        self.resumeScanningAfterDelay()
                        return
                    }

                    eventRef.updateData(["attendees": FieldValue.increment(Int64(1))]) { eventUpdateErr in
                        if let eventUpdateErr = eventUpdateErr {
                            self.scanResult = "Error incrementing attendees: \(eventUpdateErr.localizedDescription)"
                        } else {
                            self.scanResult = "Ticket scanned successfully! Welcome!"
                        }
                        self.resumeScanningAfterDelay()
                    }
                }
            }
        }
    }
    
    private func resumeScanningAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isScanning = true
            self.scannedCode = nil // Reset scanned code to allow new scans
        }
    }
}

// UIViewRepresentable to integrate AVCaptureVideoPreviewLayer
struct QRCodeScannerCameraView: UIViewRepresentable {
    @Binding var scannedCode: String?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        context.coordinator.setupCamera(in: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the view if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: QRCodeScannerCameraView
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        let videoDataOutput = AVCaptureVideoDataOutput()
        let qrCodeRequest = VNDetectBarcodesRequest()
        let videoQueue = DispatchQueue(label: "videoQueue")

        init(_ parent: QRCodeScannerCameraView) {
            self.parent = parent
            super.init()
        }

        func setupCamera(in view: UIView) {
            captureSession = AVCaptureSession()

            guard
                let videoCaptureDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .back)
            else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch { return }

            if captureSession?.canAddInput(videoInput) ?? false {
                captureSession?.addInput(videoInput)
            } else {
                return
            }

            // Add video data output for processing frames
            videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
            if captureSession?.canAddOutput(videoDataOutput) ?? false {
                captureSession?.addOutput(videoDataOutput)
            } else {
                return
            }

            // Set up preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession ?? AVCaptureSession())
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer!)

            // Start the capture session
            captureSession?.startRunning()
        }

        func captureOutput(
            _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            // Use Vision to detect QR codes
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([qrCodeRequest])

            if let observations = qrCodeRequest.results as? [VNBarcodeObservation] {
                for observation in observations {
                    if observation.symbology == .QR,
                        let scannedString = observation.payloadStringValue
                    {
                        // Found a QR code, pass it back to SwiftUI
                        DispatchQueue.main.async {
                            self.parent.scannedCode = scannedString
                            // Stop scanning temporarily
                            self.captureSession?.stopRunning()
                        }
                        return  // Process only the first detected QR code
                    }
                }
            }
        }
    }
}

#Preview {
    QRCodeScannerView(eventName: "My Event", eventId: "123")
}
