//
//  UIViewController.swift
//  InvoiceRecognition
//
//  Created by Berkay Vurkan on 11.10.2020.
//

import UIKit

extension UIViewController {

    func showToast(_ model: Toast) {
        guard view.viewWithTag(model.tag) == nil else { return }

        let label = PaddingLabel(frame: .zero)
        label.tag = model.tag
        label.topInset = 2
        label.bottomInset = 2
        label.leftInset = 4
        label.rightInset = 4
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.text = model.message
        view.addSubview(label)
        view.bringSubviewToFront(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            .init(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            .init(item: label, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -20),
            .init(item: label, attribute: .width, relatedBy: .lessThanOrEqual, toItem: view, attribute: .width, multiplier: 0.7, constant: 0),
            .init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        ])
        UIView.animate(withDuration: model.time.duration, delay: 0, options: .curveEaseIn, animations: {
            label.layoutIfNeeded()
            label.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 1, delay: model.time.duration / 2, options: .curveEaseOut, animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        })
    }

    func removeComponent(_ tag: Int) {
        guard let component = view.viewWithTag(tag) else { return }
        component.removeFromSuperview()
    }
}
