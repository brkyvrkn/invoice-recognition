//
//  RecordViewModel.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import Foundation
import AVFoundation
import UIKit
import Combine

class RecordViewModel {

    // Shared variables
    @Published var isRecording = false
    @Published var lastCapturedImage: UIImage? { didSet { analyzeFrame() } }
    @Published var detectedFrame: CGRect?
    @Published var popup: UIAlertController?

    var cameraManager: CameraManager
    private var disposables = Set<AnyCancellable>()

    // MARK: - Methods
    init() {
        self.cameraManager = CameraManager()
        self.cameraManager.delegate = self
    }

    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }

    func startRecording() {
        cameraManager.startRecording()
        cameraManager.setCaptureTimer()
        self.isRecording = true
    }

    func stopRecording() {
        cameraManager.stopRecording()
        cameraManager.stopCapturing()
        self.isRecording = false
    }

    private func analyzeFrame() {
        if let image = self.lastCapturedImage {
//            CVEventCall.shared.sendCommand(eventID: .detectFrame, data: image).sink { result in
//                if let detected = result?.data as? CGRect {
//                    self.detectedFrame = detected
//                } else if let err = result?.error {
//                    NSLog("%@ %@", err.code, err.message)
////                    self.popup = .createSimpleAlert(title: "\(err.code)", message: err.message)
//                }
//            }.store(in: &disposables)
            CVEventCall.shared.sendCommand(eventID: .detectBarcode, data: image).sink { result in
                
            }.store(in: &disposables)
        }
    }
}

extension RecordViewModel: CameraManagerDelegate {

    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage) {
        self.lastCapturedImage = capturedFrame
    }
}
