//
//  RecordViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import UIKit
import AVFoundation
import Combine

class RecordViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!

    // MARK: - Properties
    var viewModel = RecordViewModel()
    private var disposables = Set<AnyCancellable>()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.cameraManager.prepareRecordLayer(inView: self.recordView)
        self.setPublishers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.startRecording()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.viewModel.cameraManager.rotateCamera()
    }

    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }

    // MARK: - Methods
    private func setPublishers() {
        self.viewModel.$isRecording.receive(on: DispatchQueue.main).sink { isRecording in
            if isRecording {
                self.showToast(message: NSLocalizedString("recording", comment: "").capitalized, time: .veryLong)
            }
        }.store(in: &disposables)

        self.viewModel.$lastCapturedImage.receive(on: DispatchQueue.main).sink { img in
            if img != nil {
                print("=== CAPTURED ===")
            }
        }.store(in: &disposables)
    }

    // MARK: - Actions
    @IBAction func buttonTapped(_ sender: UIButton) {
        if sender == playPauseButton {
            self.viewModel.isRecording ? self.viewModel.stopRecording() : self.viewModel.startRecording()
        }
    }
}
