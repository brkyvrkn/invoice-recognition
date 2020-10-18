//
//  CarouselImageViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 18.10.2020.
//

import UIKit

class CarouselImageViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!

    // MARK: - Properties
    var source: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let img = self.source, self.imageView != nil {
            self.imageView.image = img
        }
    }
}
