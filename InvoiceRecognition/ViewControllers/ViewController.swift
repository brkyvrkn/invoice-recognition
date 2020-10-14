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

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }

    // MARK: - Methods
    private func setUI() {
        realTimeButton.setTitle(NSLocalizedString("real time recognition", comment: "").capitalized, for: .normal)
        capturedButton.setTitle(NSLocalizedString("detect from gallery", comment: "").capitalized, for: .normal)

        realTimeButton.setTitleColor(.systemGray2, for: .normal)
        capturedButton.setTitleColor(.systemGray2, for: .normal)
    }

    // MARK: - Actions
    @IBAction func buttonTapped(_ sender: UIButton) {
        if sender == realTimeButton {
            if let recordVC = self.storyboard?.instantiateViewController(withIdentifier: "RecordViewController") as? RecordViewController {
                self.navigationController?.pushViewController(recordVC, animated: true)
            }
        } else if sender == capturedButton {

        }
    }
}
