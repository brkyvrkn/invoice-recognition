//
//  BottomSlideUpViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 18.10.2020.
//

import UIKit

struct RecordOptionModel {
    var title: String
    var image: UIImage?
    var action: Selector?
    var isChecked: Bool = false
    init(title: String) {
        self.title = title
    }
    init(title: String, image: UIImage?) {
        self.title = title
        self.image = image
    }
    init(title: String, isChecked: Bool) {
        self.title = title
        self.isChecked = isChecked
    }
}

protocol BottomSlideUpDelegate: class {
    func bottomSlideUp(_ isExpanded: Bool)
    func bottomSlideUp(_ recordButtonTapped: UIButton)
    func bottomSlideUp(_ tableView: UITableView, didSelect option: RecordOptionModel, atIndexPath: IndexPath)
}

extension BottomSlideUpDelegate {
    func bottomSlideUp(_ recordButtonTapped: UIButton) {
        // Optional
    }
    func bottomSlideUp(_ isExpanded: Bool) {
        // Optional
    }
    func bottomSlideUp(_ tableView: UITableView, didSelect option: RecordOptionModel, atIndexPath: IndexPath) {
        // Optional
    }
}

class BottomSlideUpViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var notchView: UIView!
    @IBOutlet weak var optionsTableView: UITableView!
    @IBOutlet weak var recordButton: UIButton!
    // Constraints
    @IBOutlet weak var notchTopConstraint: NSLayoutConstraint!

    // MARK: - Properties
    weak var delegate: BottomSlideUpDelegate?
    let fullViewMargin: CGFloat = (UIApplication.shared.delegate as? AppDelegate)?.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? .zero
    var partialViewHeight: CGFloat {
        return UIScreen.main.bounds.height - collapsedHeight
    }
    let collapsedHeight: CGFloat = 80
    private var items = [RecordOptionModel]()
    var isExpanded: Bool = false {
        didSet {
            if self.delegate != nil {
                self.delegate?.bottomSlideUp(self.isExpanded)
            }
        }
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView(self.optionsTableView)
        initUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collapseBottomView(nil)
        initGesture()
    }

    // MARK: - Methods
    func bindOptions(withItems: [RecordOptionModel]) {
        self.items = withItems
        reloadTableView(self.optionsTableView)
    }

    private func initTableView(_ tableView: UITableView) {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorColor = .systemGray2 // same as notch color
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)    // horizontal margin
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
    }

    private func reloadTableView(_ tableView: UITableView) {
        DispatchQueue.main.async {
            let sectionIdxSet = IndexSet(integersIn: 0..<tableView.numberOfSections)
            tableView.beginUpdates()
            tableView.reloadSections(sectionIdxSet, with: .fade)
            tableView.endUpdates()
        }
    }

    private func initGesture() {
        let panName = "kSlideUpPanGesture"
        if !(view.gestureRecognizers?.contains(where: { $0.name == panName }) ?? false) {
            let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureHandler(_:)))
            gesture.name = panName
            view.addGestureRecognizer(gesture)
        }
    }

    private func initUI() {
        view.layer.shadowOffset = .init(width: 0, height: -1)
        view.layer.shadowOpacity = 0.4
        view.layer.shadowRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.cornerRadius = 16
        view.layer.setShadowWithRoundedCorners()
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        self.notchView.layer.cornerRadius = self.notchView.frame.height / 2
        self.notchView.clipsToBounds = true

        self.recordButton.layer.cornerRadius = self.recordButton.frame.height / 2
        self.recordButton.clipsToBounds = true
    }

    #warning("Unused function")
    func prepareBackgroundView() {
        var blurEffect: UIBlurEffect?
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect.init(style: .systemMaterial)
        } else {
            // Fallback on earlier versions
            blurEffect = UIBlurEffect.init(style: .light)
        }
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let bluredView = UIVisualEffectView.init(effect: blurEffect)
        bluredView.tag = 250
        bluredView.contentView.addSubview(visualEffect)

        visualEffect.frame = UIScreen.main.bounds
        bluredView.frame = UIScreen.main.bounds

        if !view.subviews.contains(where: { $0.tag == 250 }) {
            view.insertSubview(bluredView, at: 0)
        }
    }

    // MARK: - Actions
    @objc func panGestureHandler(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        let y = self.view.frame.minY

        if (y + translation.y >= self.fullViewMargin) && (y + translation.y <= self.partialViewHeight) {
            self.view.frame = CGRect(
                x: 0,
                y: y + translation.y,
                width: self.view.frame.width,
                height: self.view.frame.height
            )
            //            let yScale = (y + translation.y) / view.frame.height
            //            self.notchView.transform = .init(scaleX: 1, y: yScale)
            recognizer.setTranslation(.zero, in: self.view)
        }

        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ?
                Double((y - self.fullViewMargin) / -velocity.y) : Double((self.partialViewHeight - y) / velocity.y )
            duration = duration > 0.9 ? 0.65 : duration
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(
                        x: 0,
                        y: self.partialViewHeight,
                        width: self.view.frame.width,
                        height: self.view.frame.height
                    )
                    self.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    self.isExpanded = false
                } else {
                    self.view.frame = CGRect(
                        x: 0,
                        y: self.fullViewMargin,
                        width: self.view.frame.width,
                        height: self.view.frame.height
                    )
                    self.view.layer.maskedCorners = []
                    self.isExpanded = true
                }
            }, completion: nil)
        }
    }

    @objc func collapseBottomView(_ sender: Any?) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                let frame = self.view.frame
                self.view.frame = CGRect(
                    x: 0,
                    y: self.partialViewHeight,
                    width: frame.width,
                    height: frame.height
                )
                self.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                self.isExpanded = false
            })
        }
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        self.delegate?.bottomSlideUp(sender)
    }
}

// MARK: - Table View
extension BottomSlideUpViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        let item = self.items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.imageView?.image = item.image?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.contentMode = .scaleAspectFit
        cell.accessoryType = item.isChecked ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = self.items[indexPath.row]
        self.delegate?.bottomSlideUp(tableView, didSelect: selected, atIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
