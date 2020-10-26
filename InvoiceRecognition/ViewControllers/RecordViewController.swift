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
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var recordingLabel: PaddingLabel!

    // MARK: - Properties
    var viewModel = RecordViewModel()
    private var disposables = Set<AnyCancellable>()
    private var bottomSlideUp: BottomSlideUpViewController?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setPublishers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        addBottomSlideUp()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.cameraManager.prepareRecordLayer(inView: self.recordView)
        if self.viewModel.cameraManager.mode == .realTime {
            self.viewModel.cameraManager.setCaptureTimer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            // do action
            if self.bottomSlideUp != nil {
                self.bottomSlideUp?.collapseBottomView(nil)
            }
        }, completion: { context in
            self.recordView.layoutIfNeeded()
            self.viewModel.cameraManager.rotateCamera(inView: self.recordView)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }

    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
        bottomSlideUp = nil
    }

    // MARK: - Methods
    private func initUI() {
        let backImage = UIImage(named: "back")?.withRenderingMode(.alwaysTemplate)
        self.backButton.setImage(backImage, for: .normal)
        self.backButton.tintColor = (UIApplication.shared.delegate as? AppDelegate)?.window?.tintColor ?? UIColor.blue
        self.backButton.imageView?.contentMode = .scaleAspectFit
        self.backButton.layer.cornerRadius = self.backButton.frame.height / 2
        self.backButton.clipsToBounds = true
        self.backButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)

        self.recordingLabel.setLeftAttachtedText(
            UIImage(named: "redDot"),
            text: NSLocalizedString("recording", comment: "").capitalized
        )
        self.recordingLabel.layer.cornerRadius = 8
        self.recordingLabel.clipsToBounds = true
    }

    private func setPublishers() {
        self.viewModel.$isRecording.receive(on: DispatchQueue.main).sink { isRecording in
            self.recordingLabel.isHidden = !isRecording
            isRecording ? self.recordingLabel.startBlink() : self.recordingLabel.stopBlink()
        }.store(in: &disposables)

        self.viewModel.$popup.receive(on: DispatchQueue.main).sink { controller in
            if let popupVC = controller {
                self.present(popupVC, animated: true, completion: nil)
            }
        }.store(in: &disposables)

        self.viewModel.$bottomOptionsUpdated.receive(on: DispatchQueue.main).sink {
            if $0, let safeBottom = self.bottomSlideUp {
                safeBottom.bindOptions(withItems: self.viewModel.optionItems())
            }
        }.store(in: &disposables)
    }

    private func addBottomSlideUp() {
        if self.bottomSlideUp == nil, let slideUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BottomSlideUpViewController") as? BottomSlideUpViewController {
            addChild(slideUpVC)
            slideUpVC.view.frame = CGRect(
                x: 0,
                y: view.frame.maxY - slideUpVC.collapsedHeight,
                width: view.frame.width,
                height: view.frame.height - slideUpVC.fullViewMargin
            )
            view.addSubview(slideUpVC.view)
            slideUpVC.didMove(toParent: self)
            slideUpVC.view.layoutIfNeeded()
            self.bottomSlideUp = slideUpVC
            slideUpVC.delegate = self
            self.bottomSlideUp?.bindOptions(withItems: self.viewModel.optionItems())
        }
    }

    private func openFrameCarousel() {
        if self.viewModel.cvProcessedImageQueue.isEmpty {
            self.viewModel.popup = .createSimpleAlert(
                title: NSLocalizedString("Empty", comment: ""),
                message: NSLocalizedString("There is no detected frame yet, first you should start recording then the algorithm will start to capture the frames", comment: "")
            )
            return
        }
        if let carouselVC = self.storyboard?.instantiateViewController(withIdentifier: "CarouselContainerViewController") as? CarouselContainerViewController {
            carouselVC.modalPresentationStyle = .formSheet
            carouselVC.imgSource = self.viewModel.cvProcessedImageQueue
            if self.bottomSlideUp != nil {
                self.bottomSlideUp?.collapseBottomView(carouselVC)
            }
            present(carouselVC, animated: true, completion: nil)
        }
    }

    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.viewModel.stopRecording()
        self.viewModel.cvProcessedImageQueue.removeAll()
        self.viewModel.cameraManager.stopCapturing()
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - Bottom SlideUp
extension RecordViewController: BottomSlideUpDelegate {

    func bottomSlideUp(_ isExpanded: Bool) {
        // Expand/collapse state for bottom slide-up
    }

    func bottomSlideUp(_ tableView: UITableView, didSelect option: RecordOptionModel, atIndexPath: IndexPath) {
        // Option communication
        if atIndexPath.row == 0 {
            // Show frame stream
            openFrameCarousel()
        } else if atIndexPath.row == 1 {
            viewModel.saveLastFramesToDocuments()
        }
    }

    func bottomSlideUp(_ recordButtonTapped: UIButton) {
        self.viewModel.isRecording ? self.viewModel.stopRecording() : self.viewModel.startRecording()
    }
}
