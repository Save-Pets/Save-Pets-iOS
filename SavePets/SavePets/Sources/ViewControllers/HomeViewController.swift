//
//  ViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/04/11.
//

import UIKit
import AVFoundation
import Photos
import BSImagePicker

class HomeViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var enrollButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var backgroundView: UIImageView!
    
    // MARK: - Properties
    
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var alertViewController: UIAlertController?
    private var noseImageDict = [PHAsset: UIImage]()
    private var noseImageNumber: Int = 5
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeHomeViewController()
        self.initializeNavigationBar()
        DispatchQueue.global().async {
            self.initializePlayer()
            DispatchQueue.main.async {
                self.attachPlayerLayerToBackground()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.noseImageDict.removeAll()
        self.playPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pausePlayer()
        self.showNavigationBar()
    }
    
    // MARK: - Functions
    
    private func initializeHomeViewController() {
        self.enrollButton.roundUp(radius: 12)
        self.searchButton.roundUp(radius: 12)
    }
    
    private func initializePlayer() {
        guard let videoURL = Bundle.main.url(forResource: "main_video", withExtension: "mp4") else {
            fatalError("비디오 파일이 존재하지 않습니다!")
        }
        let videoAsset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: videoAsset)
        self.queuePlayer = AVQueuePlayer(playerItem: playerItem)
        
        guard let queuePlayer = self.queuePlayer else { return }
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        self.playerLayer = AVPlayerLayer(player: self.queuePlayer)
        self.playerLayer?.videoGravity = .resizeAspectFill
    }
    
    private func initializeNavigationBar() {
        self.navigationItem.backButtonTitle = "뒤로가기"
    }
    
    private func hideNavigationBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func showNavigationBar() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    private func playPlayer() {
        self.queuePlayer?.play()
    }
    
    private func pausePlayer() {
        self.queuePlayer?.pause()
    }
    
    private func attachPlayerLayerToBackground() {
        guard let playerLayer = self.playerLayer else { return }
        playerLayer.frame = self.backgroundView.bounds
        self.backgroundView.layer.addSublayer(playerLayer)
    }
    
    private func pushToNoseSelectionViewController(usage: SavePetsUsage) {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let noseSelectionViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.noseSelectionViewController) as? NoseSelectionViewController else {
            return
        }
        var noseArray = [UIImage]()
        
        switch usage {
        case .enrollment:
            noseArray = Array(self.noseImageDict.values)
        case .searching:
            noseArray = Array(repeating: UIImage(), count: 5)
            noseArray[0] = Array(self.noseImageDict.values)[0]
        }
        
        noseSelectionViewController.savePetsUsage = usage
        noseSelectionViewController.noseImageList = noseArray
        
        self.navigationController?.pushViewController(noseSelectionViewController, animated: true)
    }
    
    private func pushToNosePhotoShootViewConfoller(usage: SavePetsUsage) {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let nosePhotoShootViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.nosePhotoShootViewController) as? NosePhotoShootViewController else {
            return
        }
        nosePhotoShootViewController.savePetsUsage = usage
        self.navigationController?.pushViewController(nosePhotoShootViewController, animated: true)
    }
    
    private func showOptionAlert(style: UIAlertController.Style, usage: SavePetsUsage) {
        let alertTitle = usage == .enrollment ? "등록하기" : "조회하기"
        let alertMessage = "반려견의 비문을 \(alertTitle) 위해서\n사진을 촬영하거나 앨범에서 사진을 가져와 주세요"
        
        self.alertViewController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: style)
        let takePicture = UIAlertAction(title: "사진 촬영하기", style: .default) { (action) in
            self.pushToNosePhotoShootViewConfoller(usage: usage)
        }
        let pickPicture = UIAlertAction(title: "앨범에서 가져오기", style: .default) { (action) in
            self.pickNoseImages(usage: usage)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler : nil)

        
        self.alertViewController?.addAction(takePicture)
        self.alertViewController?.addAction(pickPicture)
        self.alertViewController?.addAction(cancel)
        
        guard let alertViewController = self.alertViewController else { return }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = alertViewController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
                self.present(alertViewController, animated: true, completion: nil)
            }
        } else {
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    private func showInfoAlert(selectedImageNum: Int, usage: SavePetsUsage) {
        let keyword = usage == .enrollment ? "등록하기" : "조회하기"
        let limitNum = usage == .enrollment ? 5 : 1
        let title = "\(keyword) 알림"
        let message = "사진이 \(selectedImageNum)장 선택되었습니다\n\(keyword) 위해서는 \(limitNum)장의 사진을 선택해주세요"
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertViewController.addAction(UIAlertAction(title: "선택하기", style: UIAlertAction.Style.default, handler: { _ in
            self.pickNoseImages(usage: usage)
        }))
        alertViewController.addAction(UIAlertAction(title: "취소", style: UIAlertAction.Style.cancel, handler: nil))

        self.present(alertViewController, animated: true, completion: nil)
    }
    
    @IBAction func enrollButtonTouchUp(_ sender: UIButton) {
        self.showOptionAlert(style: .actionSheet, usage: .enrollment)
        self.noseImageNumber = 5
    }
    
    @IBAction func searchButtonTouchUp(_ sender: UIButton) {
        self.showOptionAlert(style: .actionSheet, usage: .searching)
        self.noseImageNumber = 1
    }
    
    private func pickNoseImages(usage: SavePetsUsage) {
        let imagePicker = ImagePickerController()
        imagePicker.doneButtonTitle = "선택 완료"
        imagePicker.cancelButton = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil)

        presentImagePicker(imagePicker, select: { (asset) in
            DispatchQueue.global().async {
                if let selectedImage = self.getAssetImage(asset: asset) {
                    self.noseImageDict[asset] = selectedImage
                } else {
                    self.noseImageDict[asset] = UIImage()
                }
            }
        }, deselect: { (asset) in
            self.noseImageDict.removeValue(forKey: asset)
        }, cancel: { (assets) in
            self.noseImageDict.removeAll()
        }, finish: { (assets) in
            if assets.count == self.noseImageNumber {
                self.pushToNoseSelectionViewController(usage: usage)
            } else {
                self.noseImageDict.removeAll()
                DispatchQueue.main.async {
                    self.showInfoAlert(selectedImageNum: assets.count, usage: usage)
                }
            }
        })
    }
    
    func getAssetImage(asset: PHAsset) -> UIImage? {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var selectedImage: UIImage? = nil
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: option, resultHandler: { (result, info) in
            selectedImage = result
        })
        return selectedImage
    }
    
}
