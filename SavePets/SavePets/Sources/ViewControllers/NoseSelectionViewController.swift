//
//  NoseSelectionViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/03.
//

import UIKit

enum SavePetsUsage {
    case enrollment, searching
}

typealias ImageInfo = (imageView: UIImageView, isVerified: Bool, usage: Bool)

class NoseSelectionViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var mainNoseImageView: UIImageView!
    @IBOutlet weak var nose0ImageView: UIImageView!
    @IBOutlet weak var nose1ImageView: UIImageView!
    @IBOutlet weak var nose2ImageView: UIImageView!
    @IBOutlet weak var nose3ImageView: UIImageView!
    @IBOutlet weak var nose4ImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var photoChangeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    // MARK: - Variables
    
    static let enrollStartIndex: Int = 0
    static let searchStartIndex: Int = 2
    var savePetsUsage: SavePetsUsage = .enrollment {
        willSet(newValue) {
            self.selectedImageIndex = newValue == .enrollment ? NoseSelectionViewController.enrollStartIndex : NoseSelectionViewController.searchStartIndex
        }
    }
    var noseImageList: [UIImage] = []
    var noseImageViewDict: [Int: ImageInfo] = [:]
    private var selectedImageIndex: Int = enrollStartIndex
    private var imagePicker: UIImagePickerController?
    private var searchLoadingViewController: SearchLoadingViewController?
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = false
        activityIndicator.style = UIActivityIndicatorView.Style.medium
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeNoseSelectionViewController()
        self.initializeImagePickerView()
        self.initializeNavigationBar()
    }
    
    
    // MARK: - Functions
    
    private func initializeNoseSelectionViewController() {
        self.mainNoseImageView.roundUp(radius: 15)
        self.confirmButton.roundUp(radius: 12)
        self.disableConfirmButton()
        self.messageLabel.isHidden = true
        
        self.noseImageViewDict = [
            0: (imageView: self.nose0ImageView, isVerified: false, usage: false),
            1: (imageView: self.nose1ImageView, isVerified: false, usage: false),
            2: (imageView: self.nose2ImageView, isVerified: false, usage: false),
            3: (imageView: self.nose3ImageView, isVerified: false, usage: false),
            4: (imageView: self.nose4ImageView, isVerified: false, usage: false)
        ]
        
        switch savePetsUsage {
        case .enrollment:
            self.titleLabel.text = "비문 등록하기"
            self.confirmButton.setTitle("저장하기", for: .normal)
            for i in 0...4 {
                self.noseImageViewDict[i]?.usage = true
            }
        case .searching:
            self.titleLabel.text = "비문 조회하기"
            self.confirmButton.setTitle("조회하기", for: .normal)
            self.noseImageViewDict[2]?.usage = true
        }
        
        for (index, image) in noseImageList.enumerated() {
            if noseImageViewDict[index]?.usage == true {
                noseImageViewDict[index]?.imageView.roundUp(radius: 12)
                self.updateNoseImagesAndButton(index: index, image: image)
            } else {
                noseImageViewDict[index]?.imageView.isUserInteractionEnabled = false
            }
        }
        self.updateConfirmButton()
        self.updateNoseImagesAndButton(index: self.selectedImageIndex, image: self.noseImageList[self.selectedImageIndex])
        self.attachImageBorder(index: self.selectedImageIndex)
        self.updateIndicatorLabel(currentIndex: self.selectedImageIndex)
    }
    
    private func initializeImagePickerView() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.sourceType = .photoLibrary
        self.imagePicker?.allowsEditing = true
        self.imagePicker?.delegate = self
    }
    
    private func verifyImage(index: Int) -> Bool {
        
        self.attachActivityIndicator()
        
        // TODO: - CoreML로 이미지 체크해서 imageView에 뿌려주기
        DispatchQueue.global().async {
            sleep(3)
            DispatchQueue.main.async {
                // mainImageView 이미지에 계산결과 뿌려주기
            }
        }
        
        self.detachActivityIndicator()
        
        return true
    }
    
    private func updateConfirmButton() {
        var isVerified = true
        switch self.savePetsUsage {
        case .enrollment:
            for imageView in self.noseImageViewDict.values {
                isVerified = isVerified && imageView.isVerified
            }
        case .searching:
            guard let unwrappedIsVerified = self.noseImageViewDict[self.selectedImageIndex]?.isVerified else {
                return
            }
            isVerified = unwrappedIsVerified
        }
        
        isVerified ? self.enableConfirmButton() : self.disableConfirmButton()
    }
    
    private func enableConfirmButton() {
        self.confirmButton.isEnabled = true
        self.confirmButton.backgroundColor = UIColor.systemOrange
    }
    
    private func disableConfirmButton() {
        self.confirmButton.isEnabled = false
        self.confirmButton.backgroundColor = UIColor.lightGray
    }
    
    private func attachImageBorder(index: Int) {
        let color = UIColor.systemOrange.cgColor
        self.noseImageViewDict[index]?.imageView.setBorder(color: color, width: 3)
    }
    
    private func detachAllImageBorder() {
        let color = UIColor.white.cgColor
        for i in 0...4 {
            self.noseImageViewDict[i]?.imageView.setBorder(color: color, width: 0)
        }
    }
    
    private func attachDarkLayerOnImage(index: Int) {
        guard let _ = self.noseImageViewDict[index]?.imageView.subviews.filter({$0.restorationIdentifier == "DarkLayer"}).first else {
            guard let imageView = self.noseImageViewDict[index]?.imageView else { return }
            let darkLayerView = UIView()
            darkLayerView.restorationIdentifier = "DarkLayer"
            darkLayerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            darkLayerView.frame = imageView.bounds
            darkLayerView.backgroundColor = UIColor.black
            darkLayerView.alpha = 0.5
            imageView.addSubview(darkLayerView)
            return
        }
    }
    
    private func detachDarkLayerOnImage(index: Int) {
        let darkLayerView = self.noseImageViewDict[index]?.imageView.subviews.filter {$0.restorationIdentifier == "DarkLayer"}.first
        darkLayerView?.removeFromSuperview()
    }
    
    private func initializeNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        self.navigationItem.backButtonTitle = "뒤로가기"
    }
    
    private func updateNoseImagesAndButton(index: Int, image: UIImage) {
        self.mainNoseImageView.image = image
        self.noseImageViewDict[index]?.imageView.image = image
        self.noseImageList[index] = image
        
        let isVerified = self.verifyImage(index: index)
        self.noseImageViewDict[index]?.isVerified = isVerified
        if isVerified {
            self.detachDarkLayerOnImage(index: index)
        } else {
            self.attachDarkLayerOnImage(index: index)
        }
        self.updateConfirmButton()
    }
    
    private func attachActivityIndicator() {
        self.view.addSubview(self.activityIndicator)
    }
    
    private func detachActivityIndicator() {
        if self.activityIndicator.isAnimating {
            self.activityIndicator.stopAnimating()
        }
        self.activityIndicator.removeFromSuperview()
    }
    
    private func presentImagePickerViewController() {
        guard let imagePicker = self.imagePicker else { return }
        imagePicker.modalPresentationStyle = .automatic
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func pushToDogProfileViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let dogProfileViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.dogProfileViewController) as? DogProfileViewController else {
            return
        }
        self.navigationController?.pushViewController(dogProfileViewController, animated: true)
    }
    
    private func presentSearchLoadingViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let searchLoadingViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.searchLoadingViewController) as? SearchLoadingViewController else {
            return
        }
        
        self.searchLoadingViewController = searchLoadingViewController
        
        searchLoadingViewController.modalPresentationStyle = .fullScreen
        
        present(searchLoadingViewController, animated: true, completion: nil)
    }
    
    private func pushToSearchResultViewController() {
        let mainStoryboard = UIStoryboard(name: Constants.Name.mainStoryboard, bundle: nil)
        guard let searchResultViewController = mainStoryboard.instantiateViewController(identifier: Constants.Identifier.searchResultViewController) as? SearchResultViewController else {
            return
        }
        
        self.navigationController?.pushViewController(searchResultViewController, animated: true)
    }
    
    
    @IBAction func photoChangeButtonTouchUp(_ sender: UIButton) {
        self.presentImagePickerViewController()
    }
    
    @IBAction func confirmButtonTouchUp(_ sender: UIButton) {
        switch self.savePetsUsage {
        case .enrollment:
            self.pushToDogProfileViewController()
        case .searching:
            print("요청 API 보내고 로딩 VC 보여주기")
            // 로딩화면 띄우기
            self.presentSearchLoadingViewController()
            
            // TODO: - 서버로 등록 API 요청 보내기
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: {
                // 로딩화면 종료
                self.searchLoadingViewController?.dismiss(animated: true, completion: nil)
                // 결과 화면으로 넘어가기
                self.pushToSearchResultViewController()
            })
        }
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
        self.updateNoseImagesAndButton(index: currentIndex, image: self.noseImageList[currentIndex])
        self.selectedImageIndex = currentIndex
        self.updateIndicatorLabel(currentIndex: currentIndex)
        self.detachAllImageBorder()
        self.attachImageBorder(index: currentIndex)
    }
    
    private func updateIndicatorLabel(currentIndex: Int) {
        let indicatorIndex = self.savePetsUsage == .searching ? 0 : currentIndex
        let totalIndex = self.savePetsUsage == .searching ? 1 : 5
        self.indicatorLabel.text = "\(indicatorIndex + 1)/\(totalIndex)"
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension NoseSelectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var pickedImage: UIImage?
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            pickedImage = image
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            pickedImage = image
        }
        
        guard let unwrappedPickedImage = pickedImage else { return }
        self.updateNoseImagesAndButton(index: self.selectedImageIndex, image: unwrappedPickedImage)
        self.imagePicker?.dismiss(animated: true, completion: nil)
    }
}
