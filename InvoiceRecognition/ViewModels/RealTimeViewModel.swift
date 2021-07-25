//
//  RealTimeViewModel.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 28.10.2020.
//

import Foundation
import AVFoundation
import Combine

public class RealTimeViewModel: ViewModel {

    // MARK: - Properties
    @Published var recognizedBBox: CGRect?

    var cameraManager: CameraManager
    dynamic var cvProcessedImageQueue = [UIImage]()

    // MARK: - Methods
    override init() {
        self.cameraManager = CameraManager()
        super.init()
        self.cameraManager.delegate = self
        self.cameraManager.mode = .realTime
        listenEvent()
    }

    deinit {
        CVEventCall.shared.stopListening()
    }

    func listenEvent() {
        CVEventCall.shared.listen(eventID: .lastProcessedImage).sink { res in
            if let img = res?.data as? UIImage {
                self.cvProcessedImageQueue.append(img)
            }
        }.store(in: &disposables)
    }
}

// MARK: - Camera
extension RealTimeViewModel: CameraManagerDelegate {

    func cameraManager(_ videoOutput: AVCaptureOutput, _ capturedFrame: UIImage) {
        CVEventCall.shared.sendCommand(eventID: .detectFrame, data: capturedFrame)
//        CVEventCall.shared.sendCommand(eventID: .detectBarcode, data: capturedFrame)
            .timeout(.seconds(30), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { bbox in
                if let box = bbox?.data as? CGRect {
                    self.recognizedBBox = box
                }
            }
            .store(in: &disposables)
    }
}
