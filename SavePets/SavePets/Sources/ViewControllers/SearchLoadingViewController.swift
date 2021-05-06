//
//  SearchLoadingViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/06.
//

import UIKit
import AVFoundation

class SearchLoadingViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    
    // MARK: - Variables
    
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    
    
    // View Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global().async {
            self.initializePlayer()
            DispatchQueue.main.async {
                self.attachPlayerLayerToBackground()
            }
        }
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
    
    private func playPlayer() {
        self.queuePlayer?.play()
    }
    
    private func pausePlayer() {
        self.queuePlayer?.pause()
    }
    
    private func initializePlayer() {
        guard let videoURL = Bundle.main.url(forResource: "loading_video", withExtension: "mp4") else {
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
    
    @IBAction func cancelButtonTouchUp(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
