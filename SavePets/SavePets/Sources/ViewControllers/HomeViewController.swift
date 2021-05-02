//
//  ViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/04/11.
//

import UIKit
import AVFoundation

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
    
    
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeHomeViewController()
        self.initializePlayer()
        self.attachPlayerLayerToBackground()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.queuePlayer?.play()
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
    
    private func attachPlayerLayerToBackground() {
        guard let playerLayer = self.playerLayer else { return }
        playerLayer.frame = self.backgroundView.bounds
        self.backgroundView.layer.addSublayer(playerLayer)
    }
    
    private func pushToNoseSelectionViewController() {
        
    }
    
    private func showAlert(style: UIAlertController.Style, usage: String) {
        
        let alertTitle = usage == "enrollment" ? "등록하기" : "조회하기"
        let alertMessage = "반려견의 비문을 \(alertTitle) 위해서\n사진을 촬영하거나 앨범에서 사진을 가져와 주세요"
        
        self.alertViewController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: style)
        let takePicture = UIAlertAction(title: "사진 촬영하기", style: .default) { (action) in
            print("사진 촬영 뷰로 넘어가기")
        }
        let pickPicture = UIAlertAction(title: "앨범에서 가져오기", style: .default) { (action) in
            print("앨범 선택 뷰로 넘어가기")
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler : nil)

        
        self.alertViewController?.addAction(takePicture)
        self.alertViewController?.addAction(pickPicture)
        self.alertViewController?.addAction(cancel)
        
        guard let alertViewController = self.alertViewController else {
            return
        }
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    @IBAction func enrollButtonTouchUp(_ sender: UIButton) {
        self.showAlert(style: .actionSheet, usage: "enrollment")
    }
    
    @IBAction func searchButtonTouchUp(_ sender: UIButton) {
        self.showAlert(style: .actionSheet, usage: "searching")
    }
    
}

