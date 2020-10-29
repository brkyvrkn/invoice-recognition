//
//  Disposable.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 28.10.2020.
//

import Foundation
import Combine

public class Disposable: NSObject {

    // MARK: - Attribute
    var disposables = Set<AnyCancellable>()

    public override init() {}

    // MARK: - Destructor
    deinit {
        disposables.forEach {
            $0.cancel()
        }
        disposables.removeAll()
    }
}
