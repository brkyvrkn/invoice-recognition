//
//  ViewModel.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 28.10.2020.
//

import Foundation
import Combine

public class ViewModel: Disposable {

    // MARK: - Attributes
    // Shared
    @Published var popup: UIAlertController?
    @Published var toast: Toast?

    // Private
    private var target: UIViewController?

    // MARK: - Methods
    public func setTarget(_ target: UIViewController?) {
        if self.target != target {
            self.target = target
        }
    }
}
