//
//  CarouselPageViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 18.10.2020.
//

import UIKit
import Combine

protocol CarouselPageViewControllerDelegate: class {

    /// Called when the number of pages is updated.
    /// - Parameters:
    ///   - carouselPageViewController: CarouselImageViewController instance
    ///   - count: the total number of pages.
    func carouselPageViewController(_ carouselPageViewController: CarouselImageViewController,
        didUpdatePageCount count: Int)

    /// Called when the current index is updated.
    /// - Parameters:
    ///   - carouselPageViewController: CarouselImageViewController instance
    ///   - index: the index of the currently visible page.
    func carouselPageViewController(_ carouselPageViewController: CarouselImageViewController,
        didUpdatePageIndex index: Int)
}

class CarouselPageViewController: UIPageViewController {

    // MARK: - Properties
    var viewModel = CarouselPageViewModel()
    weak var carouselDelegate: CarouselPageViewControllerDelegate?
    private var disposables = Set<AnyCancellable>()

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        setPublishers()
        self.viewModel.setVCSource(self)
    }

    deinit {
        self.disposables.forEach {
            $0.cancel()
        }
        self.disposables.removeAll()
    }

    // MARK: - Methods
    private func setPublishers() {
        self.viewModel.$orderedVC.receive(on: DispatchQueue.main).sink { vcList in
            if !vcList.isEmpty, let current = vcList.first as? CarouselImageViewController {
                self.carouselDelegate?.carouselPageViewController(current, didUpdatePageCount: vcList.count)
                self.setViewControllers([current], direction: .forward, animated: true, completion: nil)
            }
        }.store(in: &disposables)
    }
}

// MARK: - Page Controller Delegate
extension CarouselPageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let firstVC = viewControllers?.first as? CarouselImageViewController {
            if let idx = self.viewModel.orderedVC.firstIndex(of: firstVC) {
                self.carouselDelegate?.carouselPageViewController(firstVC, didUpdatePageIndex: idx)
            }
        }
    }
}

// MARK: - Page Controller DataSource
extension CarouselPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = self.viewModel.orderedVC.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard self.viewModel.orderedVC.count > previousIndex else {
            return nil
        }
        return self.viewModel.orderedVC[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = self.viewModel.orderedVC.firstIndex(of: viewController) else {
            return nil
        }

        let nextIndex = viewControllerIndex + 1
        guard self.viewModel.orderedVC.count != nextIndex || self.viewModel.orderedVC.count > nextIndex else {
            return nil
        }
        return self.viewModel.orderedVC[nextIndex]
    }
}
