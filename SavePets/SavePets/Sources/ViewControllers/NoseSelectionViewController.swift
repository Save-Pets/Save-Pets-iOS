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

typealias ImageInfo = (image: UIImage, imageView: UIImageView, isVerified: Bool)

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
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var photoChangeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var noseStackView: UIStackView!
    
    // MARK: - Variables

    var savePetsUsage: SavePetsUsage = .enrollment
    var noseImageList: [UIImage] = []
    private var noseImageDict: [Int: ImageInfo] = [:]
    private var workItem: DispatchWorkItem?
    private var selectedIndex: Int = 0
    private var imagePicker: UIImagePickerController?
    private var searchLoadingViewController: SearchLoadingViewController?
    private var detectionOverlay: CALayer?
    private var requests = [VNRequest]()
    private let semaphore = DispatchSemaphore(value: 1)
    private let loadingQueue = DispatchQueue.global()
    
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
        
        self.noseImageDict = [
            0: (image: self.noseImageList[0], imageView: self.nose0ImageView, isVerified: false),
            1: (image: self.noseImageList[1], imageView: self.nose1ImageView, isVerified: false),
            2: (image: self.noseImageList[2],imageView: self.nose2ImageView, isVerified: false),
            3: (image: self.noseImageList[3],imageView: self.nose3ImageView, isVerified: false),
            4: (image: self.noseImageList[4],imageView: self.nose4ImageView, isVerified: false)
        ]
        
        switch savePetsUsage {
        case .enrollment:
            self.titleLabel.text = "비문 등록하기"
            self.confirmButton.setTitle("저장하기", for: .normal)
            for (index, image) in self.noseImageList.reversed().enumerated() {
                let newIndex = (self.noseImageList.count - 1) - index
                self.loadingQueue.async {
                    self.semaphore.wait()
                    self.updateSelectedIndex(currentIndex: newIndex)
                    DispatchQueue.main.async {
                        self.setupLayers()
                        self.noseImageDict[newIndex]?.imageView.isUserInteractionEnabled = true
                        self.noseImageDict[newIndex]?.imageView.roundUp(radius: 12)
                        self.updateNoseImages(index: newIndex, image: image)
                    }
                    self.verifyImage(index: newIndex)
                }
            }
            self.attachImageBorder(currentIndex: self.selectedIndex)
        case .searching:
            self.titleLabel.text = "비문 조회하기"
            self.confirmButton.setTitle("조회하기", for: .normal)
            for view in self.noseStackView.arrangedSubviews {
                view.isHidden = true
            }
            self.loadingQueue.async {
                self.semaphore.wait()
                DispatchQueue.main.async {
                    self.setupLayers()
                    self.updateNoseImages(index: self.selectedIndex, image: self.noseImageList[self.selectedIndex])
                }
                self.verifyImage(index: self.selectedIndex)
            }
        }
        
        self.updateIndicatorLabel(currentIndex: self.selectedIndex)
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
        if let isVerified = self.noseImageDict[index]?.isVerified {
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
            self.showOKMessage(message: "확인되었습니다")
            for shapeLayer in shapeLayers {
                self.detectionOverlay?.addSublayer(shapeLayer)
            }
            self.noseImageDict[self.selectedIndex]?.isVerified = true
            self.detachDarkLayerOnImage(index: self.selectedIndex)
        } else {
            if noseNumber == 1 && nostrilsNumber == 2 {
                self.showAlertMessage(message: "반려견 코의 크기가 충분히 크지 않습니다")
            } else if noseNumber == 0 || nostrilsNumber == 0 {
                self.showAlertMessage(message: "반려견의 코를 찾을 수 없습니다")
            } else {
                self.showAlertMessage(message: "반려견의 코가 조건에 맞지 않습니다")
            }
            self.noseImageDict[self.selectedIndex]?.isVerified = false
            self.attachDarkLayerOnImage(index: self.selectedIndex)
        }
        
        self.updateConfirmButton()
        self.semaphore.signal()
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
        switch self.savePetsUsage {
        case .enrollment:
            for index in 0...4 {
                if let isVerified = self.noseImageDict[index]?.isVerified {
                    totalIsVerified = totalIsVerified && isVerified
                }
            }
        case .searching:
            if let isVerified = self.noseImageDict[self.selectedIndex]?.isVerified {
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
        self.noseImageDict[currentIndex]?.imageView.setBorder(color: color, width: 3)
    }
    
    private func detachAllImageBorders() {
        let color = UIColor.white.cgColor
        for i in 0...4 {
            self.noseImageDict[i]?.imageView.setBorder(color: color, width: 0)
        }
    }
    
    private func attachDarkLayerOnImage(index: Int) {
        guard let _ = self.noseImageDict[index]?.imageView.subviews.filter({$0.restorationIdentifier == "DarkLayer"}).first else {
            guard let imageView = self.noseImageDict[index]?.imageView else { return }
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
        let darkLayerView = self.noseImageDict[index]?.imageView.subviews.filter {$0.restorationIdentifier == "DarkLayer"}.first
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
        self.noseImageList[index] = croppedImage
        self.noseImageDict[index]?.imageView.image = croppedImage
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
        self.selectedIndex = currentIndex
    }
    
    private func updateIndicatorLabel(currentIndex: Int) {
        let totalIndex = self.savePetsUsage == .searching ? 1 : 5
        self.indicatorLabel.text = "\(currentIndex + 1)/\(totalIndex)"
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
        self.updateNoseImages(index: self.selectedIndex, image: unwrappedPickedImage)
        self.verifyImage(index: self.selectedIndex)
        self.imagePicker?.dismiss(animated: true, completion: nil)
    }
}
