//
//  GameState.swift
//  GestureRun
//
//  Created by Baran on 25.03.2026.
//
import Foundation
import CoreGraphics

// MARK: - Oyun durumu
enum GameState {
    case waiting    // Başlamayı bekliyor
    case playing    // Oyun devam ediyor
    case paused     // Duraklatıldı
    case gameOver   // Oyun bitti
}

// MARK: - El hareketi
enum HandGesture {
    case none           // El yok
    case open           // Açık el → zıpla
    case fist           // Yumruk → çömel
    case pointLeft      // Sola işaret → sola git
    case pointRight     // Sağa işaret → sağa git
    case peace          // Victory → çift zıplama
}

// MARK: - El pozisyonu
struct HandPosition {
    let gesture: HandGesture
    let normalizedX: CGFloat  // 0.0 - 1.0
    let normalizedY: CGFloat  // 0.0 - 1.0
    let confidence: Float
    
    var isReliable: Bool { confidence > 0.7 }
    
    static let empty = HandPosition(
        gesture: .none,
        normalizedX: 0.5,
        normalizedY: 0.5,
        confidence: 0
    )
}

// MARK: - Oyun skoru
struct GameScore {
    var points: Int = 0
    var distance: Int = 0
    var coinsCollected: Int = 0
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "highScore") }
        set { UserDefaults.standard.set(newValue, forKey: "highScore") }
    }
    
    mutating func update(deltaTime: TimeInterval) {
        distance += 1
        points = distance + (coinsCollected * 10)
    }
    
    mutating func saveIfHighScore() {
        var score = self
        if points > highScore {
            score.highScore = points
        }
    }
}

// MARK: - Platform türleri
enum PlatformType {
    case normal     // Normal platform
    case moving     // Hareket eden
    case breaking   // Kırılan
    case spring     // Zıplatan
}

// MARK: - Fizik kategorileri
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let player:     UInt32 = 0b0001
    static let platform:   UInt32 = 0b0010
    static let coin:       UInt32 = 0b0100
    static let obstacle:   UInt32 = 0b1000
    static let ground:     UInt32 = 0b10000
}
