//
//  NosePhotoShootViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/03.
//

import UIKit

class NosePhotoShootViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var nose0ImageView: UIImageView!
    @IBOutlet weak var nose1ImageView: UIImageView!
    @IBOutlet weak var nose2ImageView: UIImageView!
    @IBOutlet weak var nose3ImageView: UIImageView!
    @IBOutlet weak var nose4ImageView: UIImageView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var noseStackView: UIStackView!
    @IBOutlet weak var confirmButton: UIButton!
    
    // MARK: - Variables
    
    var savePetsUsage: SavePetsUsage = .enrollment
    private var selectedIndex: Int = 0
    private var noseImageDict: [Int: ImageInfo] = [:]
    private var searchLoadingViewController: SearchLoadingViewController?
    private var workItem: DispatchWorkItem?
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeNosePhotoShootViewController()
        self.initializeNavigationBar()
    }
    
    // MARK: - Functions
    
    private func initializeNosePhotoShootViewController() {
        self.confirmButton.roundUp(radius: 12)
        self.disableConfirmButton()
        self.messageLabel.text = ""
        
        self.noseImageDict = [
            0: (image: UIImage(), imageView: self.nose0ImageView, isVerified: false),
            1: (image: UIImage(), imageView: self.nose1ImageView, isVerified: false),
            2: (image: UIImage(), imageView: self.nose2ImageView, isVerified: false),
            3: (image: UIImage(), imageView: self.nose3ImageView, isVerified: false),
            4: (image: UIImage(), imageView: self.nose4ImageView, isVerified: false)
        ]
        
        switch savePetsUsage {
        case .enrollment:
            self.confirmButton.setTitle("저장하기", for: .normal)
        case .searching:
            self.confirmButton.setTitle("조회하기", for: .normal)
            for view in self.noseStackView.arrangedSubviews {
                view.isHidden = true
            }
        }
        
        for i in 0...4 {
            self.noseImageDict[i]?.imageView.roundUp(radius: 12)
        }
        
        self.updateIndicatorLabel(currentIndex: self.selectedIndex)
        self.attachImageBorder(currentIndex: self.selectedIndex)
    }
    
    private func enableConfirmButton() {
        self.confirmButton.isEnabled = true
        self.confirmButton.backgroundColor = UIColor.systemOrange
    }
    
    private func disableConfirmButton() {
        self.confirmButton.isEnabled = false
        self.confirmButton.backgroundColor = UIColor.lightGray
    }

    private func initializeNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    private func showAlertMessage(message: String) {
        self.messageView.setBorder(color: UIColor.systemRed.cgColor, width: 1)
        self.messageView.roundUp(radius: self.messageView.frame.size.height / 2)
        self.messageView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        self.messageLabel.textColor = UIColor.systemRed
        self.messageLabel.text = message
    }
    
    private func showOKMessage(message: String) {
        self.messageView.setBorder(color: UIColor.systemGreen.cgColor, width: 1)
        self.messageView.roundUp(radius: self.messageView.frame.size.height / 2)
        self.messageView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        self.messageLabel.textColor = UIColor.systemGreen
        self.messageLabel.text = message
    }
    
    private func presentSearchLoadingViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let searchLoadingViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.searchLoadingViewController) as? SearchLoadingViewController else {
            return
        }
        
        self.searchLoadingViewController = searchLoadingViewController
        
        searchLoadingViewController.workItem = self.workItem
        searchLoadingViewController.modalPresentationStyle = .fullScreen
        
        present(searchLoadingViewController, animated: true, completion: nil)
    }
    
    private func pushToDogProfileViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let dogProfileViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.dogProfileViewController) as? DogProfileViewController else {
            return
        }
        self.navigationController?.pushViewController(dogProfileViewController, animated: true)
    }
    
    private func pushToSearchResultViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let searchResultViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.searchResultViewController) as? SearchResultViewController else {
            return
        }
        
        self.navigationController?.pushViewController(searchResultViewController, animated: true)
    }
    
    private func attachImageBorder(currentIndex: Int) {
        let color = UIColor.systemOrange.cgColor
        self.noseImageDict[currentIndex]?.imageView.setBorder(color: color, width: 3)
    }
    
    private func detachAllImageBorders() {
        let color = UIColor.white.cgColor
        for i in 0...4 {
            self.noseImageDict[i]?.imageView.setBorder(color: color, width: 0)
        }
    }
    
    @IBAction func trashButtonTouchUp(_ sender: UIButton) {
        
    }
    
    @IBAction func nose0TouchUp(_ sender: UITapGestureRecognizer) {
        self.noseTouchUp(currentIndex: 0)
    }
    
    @IBAction func nose1TouchUp(_ sender: UITapGestureRecognizer) {
        self.noseTouchUp(currentIndex: 1)
    }
    
    @IBAction func nose2TouchUp(_ sender: UITapGestureRecognizer) {
        self.noseTouchUp(currentIndex: 2)
    }
    
    @IBAction func nose3TouchUp(_ sender: UITapGestureRecognizer) {
        self.noseTouchUp(currentIndex: 3)
    }
    
    @IBAction func nose4TouchUp(_ sender: UITapGestureRecognizer) {
        self.noseTouchUp(currentIndex: 4)
    }
    
    private func noseTouchUp(currentIndex: Int) {
        print(currentIndex)
        self.detachAllImageBorders()
        self.attachImageBorder(currentIndex: currentIndex)
        self.updateIndicatorLabel(currentIndex: currentIndex)
    }
    
    private func updateSelectedIndex(currentIndex: Int) {
        self.selectedIndex = currentIndex
    }
    
    private func updateIndicatorLabel(currentIndex: Int) {
        let totalIndex = self.savePetsUsage == .searching ? 1 : 5
        self.indicatorLabel.text = "\(currentIndex + 1)/\(totalIndex)"
    }
    
    @IBAction func confirmButtonTouchUp(_ sender: UIButton) {
        switch self.savePetsUsage {
        case .enrollment:
            self.pushToDogProfileViewController()
        case .searching:
            print("요청 API 보내고 로딩 VC 보여주기")
            
            self.workItem = DispatchWorkItem {
                // 로딩화면 종료
                self.searchLoadingViewController?.dismiss(animated: true, completion: nil)
                // 결과 화면으로 넘어가기
                self.pushToSearchResultViewController()
            }
            
            // 로딩화면 띄우기
            self.presentSearchLoadingViewController()
            
            // TODO: - 서버로 등록 API 요청 보내기
            guard let safeWorkItem = workItem else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: safeWorkItem)
        }
    }
}
