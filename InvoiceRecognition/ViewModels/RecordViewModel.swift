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

class RecordViewModel: NSObject {

    // Shared variables
    @Published var isRecording = false
    @Published var lastCapturedImage: UIImage? { didSet { analyzeFrame() } }
    @Published var lastProcessedImage: UIImage?
    @Published var detectedFrame: CGRect?
    @Published var popup: UIAlertController?

    var cameraManager: CameraManager
    dynamic var cvProcessedImageQueue = [UIImage]()
    var toastTimer: Timer?
    private var disposables = Set<AnyCancellable>()

    // MARK: - Methods
    override init() {
        self.cameraManager = CameraManager()
        super.init()
        self.cameraManager.delegate = self
    }

    deinit {
        if toastTimer != nil {
            toastTimer?.invalidate()
            toastTimer = nil
        }
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }

    func startRecording() {
        if !self.cvProcessedImageQueue.isEmpty {
            self.cvProcessedImageQueue.removeAll()
        }
        cameraManager.startRecording()
        cameraManager.setCaptureTimer()
        self.isRecording = true
        self.listenEvent()
    }

    func stopRecording() {
        cameraManager.stopRecording()
        cameraManager.stopCapturing()
        self.isRecording = false
        CVEventCall.shared.stopListening()
    }

    func listenEvent() {
        CVEventCall.shared.listen(eventID: .lastProcessedImage).sink { res in
            if let img = res?.data as? UIImage {
                self.cvProcessedImageQueue.append(img)
            }
        }.store(in: &disposables)
    }

    func optionItems() -> [RecordOptionModel] {
        return [
            .init(title: NSLocalizedString("show image stream", comment: "").capitalized, action: nil),
            .init(title: NSLocalizedString("save last processed frames to documents", comment: "").capitalized, action: nil),
            .init(title: NSLocalizedString("save video to documents", comment: "").capitalized, action: nil)
        ]
    }

    func saveLastFramesToDocuments() {
        if self.cvProcessedImageQueue.isEmpty {
            self.popup = .createSimpleAlert(
                title: NSLocalizedString("info", comment: "").capitalized,
                message: NSLocalizedString("frames container does not have any image", comment: "")
            )
            return
        }
        self.cameraManager.saveImageListToDocuments(self.cvProcessedImageQueue)
        self.popup = .createSimpleAlert(
            title: NSLocalizedString("completed", comment: "").capitalized,
            message: NSLocalizedString("Images are exported to documents", comment: "")
        )
    }

    private func analyzeFrame() {
        if let image = self.lastCapturedImage {
            CVEventCall.shared.sendCommand(eventID: .detectFrame, data: image).sink { result in
                if let detected = result?.data as? UIImage {
                    self.lastProcessedImage = detected
                } else if let err = result?.error {
                    NSLog("%@ %@", err.code, err.message)
//                    self.popup = .createSimpleAlert(title: "\(err.code)", message: err.message)
                }
            }.store(in: &disposables)
//            CVEventCall.shared.sendCommand(eventID: .detectBarcode, data: image).sink { result in
//
//            }.store(in: &disposables)
        }
    }
}

extension RecordViewModel: CameraManagerDelegate {

    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage) {
        self.lastCapturedImage = capturedFrame
        print("=== CAPTURED ===")
    }
}
