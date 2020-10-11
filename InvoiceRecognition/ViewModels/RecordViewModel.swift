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

    private var asset: AVURLAsset?
    private var player: AVPlayer?
    private var session: AVCaptureSession?
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer?

    private var disposables = Set<AnyCancellable>()

    // MARK: - Methods
    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }

    func prepareVideoLayer(inView: UIView) {
        
    }
}
