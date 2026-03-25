//
//  GameViewModel.swift
//  GestureRun
//
//  Created by Baran on 25.03.2026.
//

import Foundation
import Combine
import AVFoundation
import SpriteKit

@MainActor
final class GameViewModel: ObservableObject {
    
    // MARK: - Published
    @Published var gameState: GameState = .waiting
    @Published var currentGesture: HandGesture = .none
    @Published var handPosition: HandPosition? = nil
    @Published var score: GameScore = GameScore()
    @Published var isAuthorized: Bool = false
    
    // MARK: - Services
    let cameraService: CameraService
    private let handService: HandDetectionService
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Gesture callback (GameScene dinleyecek)
    var onGestureDetected: ((HandGesture) -> Void)?
    var onHandPositionChanged: ((HandPosition?) -> Void)?
    
    // MARK: - Init
    init(
        cameraService: CameraService = CameraService(),
        handService: HandDetectionService = HandDetectionService()
    ) {
        self.cameraService = cameraService
        self.handService = handService
        bindCamera()
        bindHand()
    }
    
    // MARK: - Camera Binding
    private func bindCamera() {
        cameraService.$isAuthorized
            .receive(on: RunLoop.main)
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)
        
        cameraService.$error
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.isAuthorized = false
            }
            .store(in: &cancellables)
        
        cameraService.framePublisher
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] buffer in
                self?.handService.processFrame(buffer)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Hand Binding
    private func bindHand() {
        handService.handPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] position in
                guard let self else { return }
                self.handPosition = position
                
                let gesture = position?.isReliable == true
                    ? position!.gesture
                    : .none
                
                if gesture != self.currentGesture {
                    self.currentGesture = gesture
                    self.onGestureDetected?(gesture)
                }
                
                self.onHandPositionChanged?(position)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Controls
    func startGame() {
        score = GameScore()
        gameState = .playing
        cameraService.start()
    }
    
    func pauseGame() {
        gameState = .paused
    }
    
    func resumeGame() {
        gameState = .playing
    }
    
    func endGame() {
        gameState = .gameOver
        score.saveIfHighScore()
        cameraService.stop()
    }
    
    func resetGame() {
        gameState = .waiting
        score = GameScore()
        currentGesture = .none
        handPosition = nil
    }
    
    // MARK: - Score
    func updateScore(deltaTime: TimeInterval) {
        guard gameState == .playing else { return }
        score.update(deltaTime: deltaTime)
    }
    
    func collectCoin() {
        score.coinsCollected += 1
        score.points += 10
    }
    
    // MARK: - Camera preview
    var previewLayer: AVCaptureVideoPreviewLayer {
        cameraService.previewLayer
    }
}
