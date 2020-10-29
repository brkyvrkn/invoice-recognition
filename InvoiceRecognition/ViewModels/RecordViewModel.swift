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

class RecordViewModel: ViewModel {

    // Shared variables
    @Published var isRecording = false
    @Published var lastCapturedImage: UIImage? { didSet { analyzeFrame() } }
    @Published var lastProcessedImage: UIImage?
    @Published var detectedFrame: CGRect?
    @Published var bottomOptionsUpdated = false

    var cameraManager: CameraManager
    dynamic var cvProcessedImageQueue = [UIImage]()

    // MARK: - Methods
    override init() {
        self.cameraManager = CameraManager()
        super.init()
        self.cameraManager.delegate = self
        self.cameraManager.mode = .record
        self.listenEvent()
    }

    deinit {
        CVEventCall.shared.stopListening()
    }

    func startRecording() {
        guard cameraManager.mode == .record else {
            self.popup = .createSimpleAlert(
                title: NSLocalizedString("", comment: ""),
                message: NSLocalizedString("", comment: "")
            )
            return
        }
        if !self.cvProcessedImageQueue.isEmpty {
            self.cvProcessedImageQueue.removeAll()
        }
        cameraManager.startRecording()
        self.isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }
        cameraManager.stopRecording()
        self.isRecording = false
    }

    func listenEvent() {
        CVEventCall.shared.listen(eventID: .lastProcessedImage).sink { res in
            if let img = res?.data as? UIImage {
                self.cvProcessedImageQueue.append(img)
            }
        }.store(in: &disposables)
    }

    func optionItems() -> [RecordOptionModel] {
        let streamOption = RecordOptionModel(
            title: NSLocalizedString("show image stream", comment: "").capitalized,
            image: UIImage(named: "frames")
        )
        let saveFrameOption = RecordOptionModel(
            title: NSLocalizedString("save last processed frames", comment: "").capitalized,
            image: UIImage(named: "save")
        )
        return [
            streamOption,
            saveFrameOption
        ]
    }

    func saveLastFramesToDocuments() {
        if self.cvProcessedImageQueue.isEmpty {
            self.popup = .createSimpleAlert(
                title: NSLocalizedString("info", comment: "").capitalized,
                message: NSLocalizedString("frames container does not have any image", comment: "").capitalized
            )
            return
        }
        self.cameraManager.saveImageListToDocuments(self.cvProcessedImageQueue) {
            self.popup = .createSimpleAlert(
                title: NSLocalizedString("completed", comment: "").capitalized,
                message: NSLocalizedString("images are exported to documents", comment: "").capitalized
            )
        }
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
        }
    }
}

// MARK: - Camera
extension RecordViewModel: CameraManagerDelegate {

    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage) {
        self.lastCapturedImage = capturedFrame
        print("=== CAPTURED ===")
    }
}
