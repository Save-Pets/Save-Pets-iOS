//
//  NosePhotoShootViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/03.
//

import UIKit
import AVFoundation
import Vision

class NosePhotoShootViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var previewView: UIView!
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
    private var showResult: Bool = true
    
    private var takePicture: Bool = false
    private var touchImageView: Bool = false
    private var bufferSize: CGSize = .zero
    private var rootLayer: CALayer! = nil
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var detectionOverlay: CALayer! = nil
    private var requests = [VNRequest]()
    private let semaphore = DispatchSemaphore(value: 1)
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeNosePhotoShootViewController()
        self.initializeNavigationBar()
        self.setupAVCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopCaptureSession()
    }
    
    // MARK: - Functions
    
    private func initializeNosePhotoShootViewController() {
        self.confirmButton.roundUp(radius: 12)
        self.disableConfirmButton()
        self.messageLabel.text = ""
        
        self.noseImageDict = [
            0: (imageView: self.nose0ImageView, isVerified: false),
            1: (imageView: self.nose1ImageView, isVerified: false),
            2: (imageView: self.nose2ImageView, isVerified: false),
            3: (imageView: self.nose3ImageView, isVerified: false),
            4: (imageView: self.nose4ImageView, isVerified: false)
        ]
        
        switch savePetsUsage {
        case .enrollment:
            self.confirmButton.setTitle("저장하기", for: .normal)
        case .searching:
            self.confirmButton.setTitle("조회하기", for: .normal)
            for (index, view) in self.noseStackView.arrangedSubviews.enumerated() where index != 0 {
                view.isUserInteractionEnabled = false
                view.backgroundColor = UIColor.clear
            }
        }
        
        for i in 0...4 {
            self.noseImageDict[i]?.imageView.roundUp(radius: 12)
        }
        
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
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let searchLoadingViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.searchLoadingViewController) as? SearchLoadingViewController else {
            return
        }
        
        self.searchLoadingViewController = searchLoadingViewController
        searchLoadingViewController.modalPresentationStyle = .fullScreen
        
        present(searchLoadingViewController, animated: true, completion: nil)
    }
    
    private func presentPreviewViewController(currentIndex: Int, image: UIImage?) {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let previewViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.previewViewController) as? PreviewViewController else {
            return
        }
        self.stopCaptureSession()
        previewViewController.previewViewControllerDelegate = self
        previewViewController.previewImage = image
        previewViewController.currentIndex = currentIndex
        previewViewController.modalPresentationStyle = .automatic
        
        present(previewViewController, animated: true, completion: nil)
    }
    
    private func pushToDogProfileViewController() {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let dogProfileViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.dogProfileViewController) as? DogProfileViewController else {
            return
        }
        
        dogProfileViewController.enrollment = Enrollment(
            owner: nil,
            dog: nil,
            firstImage: self.noseImageDict[0]?.imageView.image,
            secondImage: self.noseImageDict[1]?.imageView.image,
            thirdImage: self.noseImageDict[2]?.imageView.image,
            firthImage: self.noseImageDict[3]?.imageView.image,
            fifthImage: self.noseImageDict[4]?.imageView.image
        )
        
        self.navigationController?.pushViewController(dogProfileViewController, animated: true)
    }
    
    private func pushToSearchResultViewController(result: SearchingResult) {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let searchResultViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.searchResultViewController) as? SearchResultViewController else {
            return
        }
        
        searchResultViewController.searchingResult = result
        
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
        self.touchImageView = true
        self.stopCaptureSession()
        DispatchQueue.main.async {
            self.updateSelectedIndex(newIndex: currentIndex)
            self.detachAllImageBorders()
            self.attachImageBorder(currentIndex: currentIndex)
            if self.noseImageDict[currentIndex]?.imageView.image == nil {
                self.takePicture = false
                self.startCaptureSession()
            } else {
                if let image = self.noseImageDict[currentIndex]?.imageView.image {
                    self.presentPreviewViewController(currentIndex: currentIndex, image: image)
                }
            }
        }
    }
    
    @discardableResult
    private func updateSelectedIndex(newIndex: Int) -> Bool {
        let maxNoseNum = self.savePetsUsage == .enrollment ? 5 : 1
        if newIndex >= maxNoseNum {
            return false
        }
        self.selectedIndex = newIndex
        return true
    }
    
    private func updatePreviewImageView(image: UIImage) {
        let currentImageLayer = CALayer()
        currentImageLayer.bounds = self.rootLayer.bounds
        currentImageLayer.contents = image.cgImage
        currentImageLayer.contentsGravity = .resizeAspectFill
        self.previewView.layer.sublayers = nil
        self.previewView.layer.insertSublayer(currentImageLayer, at: 0)
    }
    
    private func updateNoseImages(index: Int, image: UIImage) {
        let capturedImage = image.crop(to: CGSize(width: 640, height: 640))
        self.noseImageDict[index]?.imageView.image = capturedImage
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
    
    @IBAction func confirmButtonTouchUp(_ sender: UIButton) {
        switch self.savePetsUsage {
        case .enrollment:
            self.pushToDogProfileViewController()
        case .searching:
            self.showResult = true
            DispatchQueue.global().async {
                self.postSearchingWithAPI(dogNose: self.noseImageDict[0]?.imageView.image) { (result) in
                    if self.showResult {
                        self.searchLoadingViewController?.dismiss(animated: true, completion: {
                            self.pushToSearchResultViewController(result: result)
                        })
                    }
                }
            }
            self.presentSearchLoadingViewController()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension NosePhotoShootViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if !self.takePicture {
            self.detectDogNose(pixelBuffer: pixelBuffer)
            return
        }
        
        self.semaphore.wait()

        DispatchQueue.main.async {
            
            let ciImage = CIImage(cvImageBuffer: pixelBuffer).oriented(.right)
            let uiImage = UIImage(ciImage: ciImage)
            
            self.presentPreviewViewController(currentIndex: self.selectedIndex, image: uiImage)
            
            if self.touchImageView {
                return
            }
            
            if !self.touchImageView {
                self.updateSelectedIndex(newIndex: self.selectedIndex + 1)
                self.detachAllImageBorders()
                self.attachImageBorder(currentIndex: self.selectedIndex)
            }
        }
        self.semaphore.signal()
    }
    
    
    func detectDogNose(pixelBuffer: CVImageBuffer) {
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    func setupInputs() {
        var deviceInput: AVCaptureDeviceInput!
        
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.sessionPreset = .vga640x480
        
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        
        do {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func setupOutputs() {
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true

    }
    
    func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.insertSublayer(previewLayer, at: 0)
    }
    
    func setupAVCapture() {
        self.session.beginConfiguration()
        self.setupInputs()
        self.setupOutputs()
        self.session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.setupPreviewLayer()
            self.setupLayers()
            self.updateLayerGeometry()
        }
        
        self.setupVision()
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    func stopCaptureSession() {
        session.stopRunning()
    }
    
    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:
            exifOrientation = .down
        case UIDeviceOrientation.portrait:
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    @discardableResult
    func setupVision() -> NSError? {
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "DogNoseDetector", withExtension: "mlmodelc") else {
            return NSError(domain: "NosePhotoShootViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: handleResults(request:error:))
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    private func handleResults(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.drawVisionRequestResults(results)
            }
        })
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil
        var isSatisfiedSizeOfNose = false
        var noseNumber = 0
        var nostrilsNumber = 0
        var shapeLayers = [CALayer]()
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            
            let topLabelObservation = objectObservation.labels[0]
            let topLabelObservationBoundingBoxes = objectObservation.boundingBox
            let topLabelObservationLabel = topLabelObservation.identifier
            let objectBounds = VNImageRectForNormalizedRect(topLabelObservationBoundingBoxes, Int(bufferSize.width), Int(bufferSize.height))
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            detectionOverlay.addSublayer(shapeLayer)
            
            if topLabelObservationLabel == "nose" {
                noseNumber += 1
                print(topLabelObservationBoundingBoxes)
                if topLabelObservationBoundingBoxes.width >= 0.4 && topLabelObservationBoundingBoxes.height >= 0.8 {
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
            self.takePicture = true
        } else {
            if noseNumber == 1 && nostrilsNumber == 2 {
                self.showAlertMessage(message: "반려견 코의 크기가 충분히 크지 않습니다")
            } else if noseNumber == 0 || nostrilsNumber == 0 {
                self.showAlertMessage(message: "반려견의 코를 찾을 수 없습니다")
            } else {
                self.showAlertMessage(message: "반려견의 코가 조건에 맞지 않습니다")
            }
            self.takePicture = false
        }
        
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.bounds = CGRect(x: 0.0, y: 0.0, width: bufferSize.width, height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.borderColor = UIColor.systemOrange.cgColor
        shapeLayer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        shapeLayer.borderWidth = 2
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.cornerRadius = 1
        return shapeLayer
    }
}

// MARK: - PreviewViewControllerDelegate

extension NosePhotoShootViewController: PreviewViewControllerDelegate {
    func deleteButtonTouchUp(currentIndex: Int) {
        self.noseImageDict[currentIndex]?.imageView.image = nil
        self.noseImageDict[currentIndex]?.isVerified = false
        self.updateConfirmButton()
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(1500)) {
            self.takePicture = false
            self.startCaptureSession()
        }
    }
    
    func confirmButtonTouchUp(currentIndex: Int, previewImage: UIImage?) {
        self.noseImageDict[currentIndex]?.imageView.image = previewImage
        self.noseImageDict[currentIndex]?.isVerified = true
        self.updateConfirmButton()
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(1500)) {
            self.takePicture = false
            self.startCaptureSession()
        }
    }
}

// MARK: - SearchLoadingViewControllerDelegate
extension NosePhotoShootViewController: SearchLoadingViewControllerDelegate {
    func cancelButtonTouchUp() {
        self.showResult = false
    }
}

// MARK: - API Services

extension NosePhotoShootViewController {
    
    private func postSearchingWithAPI(
        dogNose: UIImage?,
        completion: @escaping (SearchingResult) -> Void
    ) {
        guard let dogNoseImage = dogNose else { return }
        
        SearchingService.shared.postSearching(noseImage: dogNoseImage) { (result) in
            switch result {
            case .success(let data):
                if let searchingResult = data as? SearchingResult {
                    DispatchQueue.main.async {
                        completion(searchingResult)
                    }
                }
            case .requestErr:
                print("requestErr")
            case .pathErr:
                print("pathErr")
            case .serverErr:
                print("serverErr")
            case .networkFail:
                print("networkFail")
            }
        }
    }
}
