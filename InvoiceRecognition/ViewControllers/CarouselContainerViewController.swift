//
//  CarouselContainerViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 18.10.2020.
//

import UIKit

class CarouselContainerViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pageControl: UIPageControl!

    // MARK: - Properties
    var imgSource = [UIImage]()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let carouselPageVC = segue.destination as? CarouselPageViewController {
            carouselPageVC.viewModel.imageSource = imgSource
            carouselPageVC.carouselDelegate = self
        }
    }
}

// MARK: - Carousel Delegate
extension CarouselContainerViewController: CarouselPageViewControllerDelegate {

    func carouselPageViewController(_ carouselPageViewController: CarouselImageViewController, didUpdatePageCount count: Int) {
        DispatchQueue.main.async {
            self.pageControl.numberOfPages = count
            self.pageControl.layoutIfNeeded()
        }
    }

    func carouselPageViewController(_ carouselPageViewController: CarouselImageViewController, didUpdatePageIndex index: Int) {
        DispatchQueue.main.async {
            self.pageControl.currentPage = index
        }
    }
}
