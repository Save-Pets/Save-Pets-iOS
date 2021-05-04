//
//  UIVIew+Extension.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/03.
//

import UIKit

extension UIView {
    
    func roundUp(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
    func setBorder(color: CGColor, width: CGFloat) {
        self.layer.borderColor = color
        self.layer.borderWidth = width
    }
}
