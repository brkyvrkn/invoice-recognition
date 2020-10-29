//
//  RealTimeRecognitionViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 27.10.2020.
//

import UIKit
import Combine

private let cameraViewTag = 20

class RealTimeRecognitionViewController: UIViewController {

    // MARK: - Views
    private var cameraView = UIView()
    private var bboxLayer: CAShapeLayer?

    // MARK: - Properties
    var viewModel = RealTimeViewModel()
    private var disposables = Set<AnyCancellable>()

    // MARK: - Life Cycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        cameraView.tag = cameraViewTag
        setPublishers()
    }

    override func loadView() {
        super.loadView()
        self.viewModel.setTarget(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.cameraManager.prepareRecordLayer(inView: self.cameraView)
        self.viewModel.cameraManager.setCaptureTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.viewWithTag(cameraViewTag) == nil {
            view.addSubview(cameraView)
            // Add constraints
            setCameraViewConstraints()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            // do action
        }, completion: { context in
            self.cameraView.layoutIfNeeded()
            self.viewModel.cameraManager.rotateCamera(inView: self.cameraView)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            self.viewModel.cameraManager.stopCapturing()
            self.viewModel.cameraManager.stopSession()
            self.viewModel.cameraManager.clearTempFiles()
        }
    }

    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }

    // MARK: - Methods
    private func initUI() {
        
    }

    private func setPublishers() {
        self.viewModel.$popup.receive(on: DispatchQueue.main).sink { popup in
            if let safePopup = popup {
                self.present(safePopup, animated: true, completion: nil)
            }
        }.store(in: &disposables)

        self.viewModel.$toast.receive(on: DispatchQueue.main).sink { toast in
            if let safeToast = toast {
                self.showToast(safeToast)
            }
        }.store(in: &disposables)

        self.viewModel.$recognizedBBox.receive(on: DispatchQueue.main).sink { rect in
            if let bbox = rect {
                // Retrieved in 1920x1080 format
                let absoluteFrame = self.viewModel.cameraManager.convertCoordSpace(frame: bbox, inView: self.cameraView)
//                let absoluteFrame = self.convertRelativeFrame(bbox, inView: self.cameraView)
                self.drawBBoxIntoCamera(absoluteFrame)
            }
        }.store(in: &disposables)
    }

    private func drawBBoxIntoCamera(_ frame: CGRect) {
        if bboxLayer != nil {
            bboxLayer?.removeAllAnimations()
            bboxLayer?.removeFromSuperlayer()
        }
        bboxLayer = CAShapeLayer()
        let bboxPath = UIBezierPath(roundedRect: frame, cornerRadius: 4)
        bboxLayer?.path = bboxPath.cgPath
        bboxLayer?.strokeColor = UIColor.blue.cgColor
        bboxLayer?.fillColor = UIColor.clear.cgColor
        bboxLayer?.lineWidth = 3
        bboxLayer?.name = "RECOGNIZED_BOUNDING_BOX"
        if let safeLayer = bboxLayer {
            self.cameraView.layer.addSublayer(safeLayer)
        }
    }

    private func setCameraViewConstraints() {
        guard view.viewWithTag(cameraViewTag) != nil else { return }
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            .init(item: cameraView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            .init(item: cameraView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            .init(item: cameraView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            .init(item: cameraView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        ])
        cameraView.layoutIfNeeded()
    }
}
