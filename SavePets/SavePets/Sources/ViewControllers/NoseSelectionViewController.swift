//
//  NoseSelectionViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/03.
//

import UIKit
import CoreML
import Vision

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
    private var workItem: DispatchWorkItem?
    private var selectedImageIndex: Int = enrollStartIndex
    private var imagePicker: UIImagePickerController?
    private var searchLoadingViewController: SearchLoadingViewController?
    private var detectionOverlay: CALayer?
    private var requests = [VNRequest]()
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeNoseSelectionViewController()
        self.initializeImagePickerView()
        self.initializeNavigationBar()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Functions
    
    private func initializeNoseSelectionViewController() {
        
        self.setupVision()
        self.mainNoseImageView.roundUp(radius: 15)
        self.confirmButton.roundUp(radius: 12)
        self.disableConfirmButton()
        self.messageLabel.text = ""
        
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
        DispatchQueue.main.async {
            self.setupLayers()
            for (index, image) in self.noseImageList.reversed().enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds((index + 1) * 300)) {
                    let newIndex = (self.noseImageList.count - 1) - index
                    if self.noseImageViewDict[newIndex]?.usage == true {
                        self.updateSelectedIndex(currentIndex: newIndex)
                        self.noseImageViewDict[newIndex]?.imageView.isUserInteractionEnabled = true
                        self.noseImageViewDict[newIndex]?.imageView.roundUp(radius: 12)
                        self.updateNoseImages(index: newIndex, image: image)
                        self.verifyImage(index: newIndex)
                    }
                }
            }
            self.attachImageBorder(currentIndex: self.selectedImageIndex)
            self.updateIndicatorLabel(currentIndex: self.selectedImageIndex)
        }
    }
    
    private func initializeImagePickerView() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.sourceType = .photoLibrary
        self.imagePicker?.allowsEditing = true
        self.imagePicker?.delegate = self
    }
    
    private func verifyImage(index: Int) {
        guard let ciImage = CIImage(image: self.noseImageList[index]) else { return }
        self.detectDogNose(image: ciImage)
    }
    
    private func updateDarkLayerOnImage(index: Int) {
        if let isVerified = self.noseImageViewDict[index]?.isVerified {
            if isVerified {
                self.detachDarkLayerOnImage(index: index)
            } else {
                self.attachDarkLayerOnImage(index: index)
            }
        }
    }
    
    private func setupLayers() {
        self.detectionOverlay = CALayer()
        self.detectionOverlay?.bounds = CGRect(x: 0.0,
                                               y: 0.0,
                                               width: self.mainNoseImageView.frame.size.width,
                                               height: self.mainNoseImageView.frame.size.height)
        self.detectionOverlay?.position = CGPoint(x: self.mainNoseImageView.bounds.midX, y: self.mainNoseImageView.bounds.midY)
        if let overlay = self.detectionOverlay {
            self.mainNoseImageView.layer.addSublayer(overlay)
        }
    }
    
    @discardableResult
    private func setupVision() -> NSError? {
        let error: NSError! = nil
        guard let modelURL = Bundle.main.url(forResource: "DogNoseDetector", withExtension: "mlmodelc") else {
            return NSError(domain: "NoseSelectionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "모델 파일이 존재하지 않습니다"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let request = VNCoreMLRequest(model: visionModel, completionHandler: self.handleResults(request: error:))
            request.imageCropAndScaleOption = .scaleFill
            
            self.requests = [request]
        } catch let error as NSError {
            print("모델을 불러오는 과정에서 오류가 발생했습니다: \(error)")
        }
        return error
    }
    
    private func handleResults(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results {
                self.drawVisionRequestResults(results)
            }
        }
    }
    
    private func detectDogNose(image: CIImage) {
        let imageRequestHandler = VNImageRequestHandler(ciImage: image, orientation: .up, options:[:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        
    }
    
    private func drawVisionRequestResults(_ results: [Any]) {
        self.detectionOverlay?.sublayers = nil
        var shapeLayers = [CALayer]()
        var isSatisfiedSizeOfNose = false
        var noseNumber = 0
        var nostrilsNumber = 0
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            
            // 제일 확률이 높은 라벨을 고른다
            let topLabelObservation = objectObservation.labels[0]
            let topLabelObservationBoundingBoxes = objectObservation.boundingBox
            // let topLabelObservationConfidence = topLabelObservation.confidence
            let topLabelObservationLabel = topLabelObservation.identifier
            
            let objectBounds = VNImageRectForNormalizedRect(topLabelObservationBoundingBoxes, Int(self.mainNoseImageView.bounds.width), Int(self.mainNoseImageView.bounds.height))
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            if topLabelObservationLabel == "nose" {
                noseNumber += 1
                if topLabelObservationBoundingBoxes.width >= 0.6 && topLabelObservationBoundingBoxes.height >= 0.6 {
                    isSatisfiedSizeOfNose = true
                    shapeLayers.append(shapeLayer)
                }
            } else if topLabelObservationLabel == "nostrils" {
                nostrilsNumber += 1
            }
        }
        
        if noseNumber == 1 && nostrilsNumber == 2 && isSatisfiedSizeOfNose {
            self.showOKMessage(message: "통과되었습니다")
            for shapeLayer in shapeLayers {
                self.detectionOverlay?.addSublayer(shapeLayer)
            }
            self.noseImageViewDict[self.selectedImageIndex]?.isVerified = true
            self.detachDarkLayerOnImage(index: self.selectedImageIndex)
        } else {
            if noseNumber == 1 && nostrilsNumber == 2 {
                self.showAlertMessage(message: "반려견 코의 크기가 충분히 크지 않습니다")
            } else if noseNumber == 0 || nostrilsNumber == 0 {
                self.showAlertMessage(message: "반려견의 코를 찾을 수 없습니다")
            } else {
                self.showAlertMessage(message: "반려견의 코가 조건에 맞지 않습니다")
            }
            self.noseImageViewDict[self.selectedImageIndex]?.isVerified = false
            self.attachDarkLayerOnImage(index: self.selectedImageIndex)
        }
        
        self.updateConfirmButton()
    }
    
    private func showAlertMessage(message: String) {
        self.messageLabel.textColor = UIColor.darkGray
        self.messageLabel.text = message
    }
    
    private func showOKMessage(message: String) {
        self.messageLabel.textColor = UIColor.systemOrange
        self.messageLabel.text = message
    }
    
    private func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.borderColor = UIColor.systemOrange.cgColor
        shapeLayer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        shapeLayer.borderWidth = 2
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.cornerRadius = 1
        return shapeLayer
    }
    
    private func updateConfirmButton() {
        var totalIsVerified = true
        for index in 0...4 where self.noseImageViewDict[index]?.usage == true {
            if let isVerified = self.noseImageViewDict[index]?.isVerified {
                totalIsVerified = totalIsVerified && isVerified
            }
        }
        totalIsVerified ? self.enableConfirmButton() : self.disableConfirmButton()
    }
    
    private func enableConfirmButton() {
        self.confirmButton.isEnabled = true
        self.confirmButton.backgroundColor = UIColor.systemOrange
    }
    
    private func disableConfirmButton() {
        self.confirmButton.isEnabled = false
        self.confirmButton.backgroundColor = UIColor.lightGray
    }
    
    private func attachImageBorder(currentIndex: Int) {
        let color = UIColor.systemOrange.cgColor
        self.noseImageViewDict[currentIndex]?.imageView.setBorder(color: color, width: 3)
    }
    
    private func detachAllImageBorders() {
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
    
    private func updateNoseImages(index: Int, image: UIImage) {
        let croppedImage = image.crop(to: CGSize(width: 640, height: 640))
        self.mainNoseImageView.image = croppedImage
        self.noseImageViewDict[index]?.imageView.image = croppedImage
        self.noseImageList[index] = croppedImage
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
        
        searchLoadingViewController.workItem = self.workItem
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
        // 이미지 갱신
        self.updateNoseImages(index: currentIndex, image: self.noseImageList[currentIndex])
        
        // 인덱스 업데이트
        self.updateSelectedIndex(currentIndex: currentIndex)
        self.updateIndicatorLabel(currentIndex: currentIndex)
        
        // 이미지 경계선 업데이트
        self.detachAllImageBorders()
        self.attachImageBorder(currentIndex: currentIndex)
        
        // 이미지 검사
        self.verifyImage(index: currentIndex)
    }
    
    private func updateSelectedIndex(currentIndex: Int) {
        self.selectedImageIndex = currentIndex
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
        self.updateNoseImages(index: self.selectedImageIndex, image: unwrappedPickedImage)
        self.verifyImage(index: self.selectedImageIndex)
        self.imagePicker?.dismiss(animated: true, completion: nil)
    }
}
