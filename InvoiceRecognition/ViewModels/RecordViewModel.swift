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
    @Published var lastCapturedImage: UIImage?

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
        cameraManager.startRunning()
        cameraManager.setCaptureTimer()
    }

    func stopRecording() {
        cameraManager.stopRecording()
        cameraManager.stopCapturing()
    }
}

extension RecordViewModel: CameraManagerDelegate {

    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage) {
        self.lastCapturedImage = capturedFrame
    }
}
