//
//  CameraService.swift
//  GestureRun
//
//  Created by Baran on 25.03.2026.
//

import AVFoundation
import Combine

final class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published
    @Published var isRunning: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var error: CameraError?
    
    // MARK: - Public
    let previewLayer: AVCaptureVideoPreviewLayer
    let framePublisher = PassthroughSubject<CMSampleBuffer, Never>()
    
    // MARK: - Private
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.gesturerun.camera.session")
    private let outputQueue = DispatchQueue(label: "com.gesturerun.camera.output")
    
    // MARK: - Init
    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    private func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isAuthorized = true }
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            DispatchQueue.main.async { self.error = .notAuthorized }
        }
    }
    
    // MARK: - Setup
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else {
                DispatchQueue.main.async { self.error = .deviceNotFound }
                self.session.commitConfiguration()
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
            } catch {
                DispatchQueue.main.async { self.error = .setupFailed }
                self.session.commitConfiguration()
                return
            }
            
            self.videoOutput.setSampleBufferDelegate(self, queue: self.outputQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            
            self.session.commitConfiguration()
        }
    }
    
    // MARK: - Controls
    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }
}

// MARK: - Sample Buffer Delegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        framePublisher.send(sampleBuffer)
    }
}

// MARK: - Errors
enum CameraError: LocalizedError {
    case notAuthorized
    case deviceNotFound
    case setupFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Kamera izni verilmedi."
        case .deviceNotFound: return "Kamera bulunamadı."
        case .setupFailed:   return "Kamera kurulumu başarısız."
        }
    }
}
