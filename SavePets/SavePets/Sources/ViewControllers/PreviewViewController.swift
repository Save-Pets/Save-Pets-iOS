//
//  PreviewViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/11.
//

import UIKit

protocol PreviewViewControllerDelegate {
    func deleteButtonTouchUp(currentIndex: Int)
    func confirmButtonTouchUp(currentIndex: Int, previewImage: UIImage?)
}

class PreviewViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    
    // MARK: - Variables
    
    var previewViewControllerDelegate: PreviewViewControllerDelegate?
    var previewImage: UIImage?
    var currentIndex: Int?
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializePreviewViewController()
    }
    
    // MARK: - Functions
    
    private func initializePreviewViewController() {
        self.previewImageView.roundUp(radius: 15)
        self.confirmButton.roundUp(radius: 12)
        self.previewImageView.image = self.previewImage
    }
    
    @IBAction func deleteButtonTouchUp(_ sender: UIButton) {
        guard let currentIndex = self.currentIndex else { return }
        self.previewViewControllerDelegate?.deleteButtonTouchUp(currentIndex: currentIndex)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmButtonTouchUp(_ sender: UIButton) {
        guard let currentIndex = self.currentIndex else { return }
        self.previewViewControllerDelegate?.confirmButtonTouchUp(currentIndex: currentIndex, previewImage: self.previewImageView.image)
        self.dismiss(animated: true, completion: nil)
    }
}
