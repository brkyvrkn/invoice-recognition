//
//  CarouselPageViewModel.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 18.10.2020.
//

import Foundation
import Combine

public class CarouselPageViewModel {

    @Published var orderedVC = [UIViewController]()
    @Published var imageSource = [UIImage]()

    private var disposables = Set<AnyCancellable>()

    // MARK: - Methods
    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }

    func setVCSource(_ target: UIViewController) {
        if !orderedVC.isEmpty {
            orderedVC.removeAll()
        }
        var temp = [UIViewController]()
        for img in self.imageSource {
            if let carouselImageVC = target.storyboard?.instantiateViewController(withIdentifier: "CarouselImageViewController") as? CarouselImageViewController {
                carouselImageVC.source = img
                temp.append(carouselImageVC)
            }
        }
        self.orderedVC = temp
    }
}
