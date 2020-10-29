//
//  ViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var realTimeButton: UIButton!
    @IBOutlet weak var capturedButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }

    // MARK: - Methods
    private func setUI() {
        realTimeButton.setTitle(NSLocalizedString("real time recognition", comment: "").capitalized, for: .normal)
        capturedButton.setTitle(NSLocalizedString("detect from gallery", comment: "").capitalized, for: .normal)
        recordButton.setTitle(NSLocalizedString("record", comment: "").capitalized, for: .normal)

        realTimeButton.setTitleColor(.systemGray3, for: .normal)
        capturedButton.setTitleColor(.systemGray3, for: .normal)
        recordButton.setTitleColor(.systemGray3, for: .normal)
    }

    // MARK: - Actions
    @IBAction func buttonTapped(_ sender: UIButton) {
        if sender == realTimeButton {
            let realTimeVC = RealTimeRecognitionViewController(nibName: "RealTimeRecognitionViewController", bundle: .main)
            self.navigationController?.pushViewController(realTimeVC, animated: true)
        } else if sender == capturedButton {

        } else if sender == recordButton {
            if let recordVC = self.storyboard?.instantiateViewController(withIdentifier: "RecordViewController") as? RecordViewController {
                self.navigationController?.pushViewController(recordVC, animated: true)
            }
        }
    }
}
