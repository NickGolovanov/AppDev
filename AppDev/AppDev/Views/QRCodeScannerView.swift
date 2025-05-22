//
//  QRCodeScannerView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/8/25.
//

import SwiftUI
import AVFoundation
import Vision
import FirebaseFirestore

struct QRCodeScannerView: View {
    @State private var scannedCode: String? = nil
    @State private var scanResult: String = "Scanning..."
    @State private var isScanning = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Scan QR Code")
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
        // Prevent rescanning the same code immediately
        self.isScanning = false
        self.scanResult = "Processing ticket..."

        let db = Firestore.firestore()
        db.collection("tickets").document(ticketId).getDocument { document, error in
            if let document = document, document.exists {
                if let used = document.data()?["used"] as? Bool, !used {
                    // Ticket exists and is not used, mark as used
                    db.collection("tickets").document(ticketId).updateData(["used": true]) { err in
                        if let err = err {
                            self.scanResult = "Error updating ticket: \(err.localizedDescription)"
                        } else {
                            self.scanResult = "Ticket scanned successfully!"
                        }
                        // Allow scanning again after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.isScanning = true }
                    }
                } else if let used = document.data()?["used"] as? Bool, used {
                    self.scanResult = "Ticket already used."
                    // Allow scanning again after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.isScanning = true }
                }
                else {
                     self.scanResult = "Ticket data incomplete."
                     // Allow scanning again after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.isScanning = true }
                }
            } else {
                self.scanResult = "Ticket not found."
                // Allow scanning again after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.isScanning = true }
            }
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

            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch { return }

            if (captureSession?.canAddInput(videoInput) ?? false) {
                captureSession?.addInput(videoInput)
            } else { return }

            // Add video data output for processing frames
            videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
            if (captureSession?.canAddOutput(videoDataOutput) ?? false) {
                captureSession?.addOutput(videoDataOutput)
            } else { return }

            // Set up preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession ?? AVCaptureSession())
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer!)

            // Start the capture session
            captureSession?.startRunning()
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            // Use Vision to detect QR codes
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([qrCodeRequest])

            if let observations = qrCodeRequest.results as? [VNBarcodeObservation] {
                for observation in observations {
                    if observation.symbology == .QR, let scannedString = observation.payloadStringValue {
                        // Found a QR code, pass it back to SwiftUI
                        DispatchQueue.main.async {
                            self.parent.scannedCode = scannedString
                            // Stop scanning temporarily
                            self.captureSession?.stopRunning()
                        }
                        return // Process only the first detected QR code
                    }
                }
            }
        }
    }
}

#Preview {
    QRCodeScannerView()
} 