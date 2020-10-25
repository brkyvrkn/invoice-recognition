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

    // MARK: - Properties
    var viewModel = RecordViewModel()
    private var disposables = Set<AnyCancellable>()
    private var bottomSlideUp: BottomSlideUpViewController?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setPublishers()
        addBottomSlideUp()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.cameraManager.prepareRecordLayer(inView: self.recordView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.viewModel.cameraManager.rotateCamera(inView: self.recordView)
        if self.bottomSlideUp != nil {
            self.bottomSlideUp?.collapseBottomView(nil)
        }
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
        let backImage = UIImage(systemName: "backIcon")?.withRenderingMode(.alwaysTemplate)
        self.backButton.setImage(backImage, for: .normal)
        self.backButton.tintColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
    }

    private func setPublishers() {
        self.viewModel.$isRecording.receive(on: DispatchQueue.main).sink { isRecording in
            //TODO: blinking label

//            if isRecording && self.viewModel.toastTimer == nil {
//                self.viewModel.toastTimer = Timer.scheduledTimer(withTimeInterval: ToastTime.veryShort.duration, repeats: true, block: { _ in
//                    self.showToast(message: NSLocalizedString("recording", comment: "").capitalized, time: .veryShort)
//                })
//            } else if !isRecording && self.viewModel.toastTimer != nil {
//                self.viewModel.toastTimer?.invalidate()
//                self.viewModel.toastTimer = nil
//                self.removeToast()
//            }
        }.store(in: &disposables)

        self.viewModel.$detectedFrame.receive(on: DispatchQueue.main).sink { pointRect in

        }.store(in: &disposables)

        self.viewModel.$popup.receive(on: DispatchQueue.main).sink { controller in
            if let popupVC = controller {
                self.present(popupVC, animated: true, completion: nil)
            }
        }.store(in: &disposables)
    }

    private func addBottomSlideUp() {
        if self.bottomSlideUp == nil, let slideUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BottomSlideUpViewController") as? BottomSlideUpViewController {
            addChild(slideUpVC)
            slideUpVC.view.frame = CGRect(
                x: 0,
                y: view.frame.maxY,
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
        if self.viewModel.isRecording {
            self.viewModel.stopRecording()
        }
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
        }
    }

    func bottomSlideUp(_ recordButtonTapped: UIButton) {
        self.viewModel.isRecording ? self.viewModel.stopRecording() : self.viewModel.startRecording()
    }
}
