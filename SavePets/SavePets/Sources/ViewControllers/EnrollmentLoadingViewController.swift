//
//  EnrollmentLoadingViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/06.
//

import UIKit
import AVFoundation

class EnrollmentLoadingViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var dogNameLabel: UILabel!
    
    // MARK: - Variables
    
    var dogName: String?
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    
    // MARK: - View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeEnrollmentLoadingViewController()
        self.initializePlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.attachPlayerLayerToBackground()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.playPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pausePlayer()
    }
    
    // Functions
    
    private func initializeEnrollmentLoadingViewController() {
        self.dogNameLabel.text = dogName
    }
    
    private func playPlayer() {
        self.queuePlayer?.play()
    }
    
    private func pausePlayer() {
        self.queuePlayer?.pause()
    }
    
    private func initializePlayer() {
        guard let videoURL = Bundle.main.url(forResource: "loading_video2", withExtension: "mp4") else {
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
        playerLayer.frame = self.backgroundImageView.bounds
        self.backgroundImageView.layer.addSublayer(playerLayer)
    }

}
