//
//  GameState.swift
//  GestureRun
//
//  Created by Baran on 25.03.2026.
//

import Foundation
import CoreGraphics

// Mark: Oyun Durumu
enum GameState {
    case waiting // Başlamayı bekliyor
    case playing // Oyun devam ediyor
    case paused // Duraklatıldı
    case gameOver // Oyun Bitti
}

enum HandGesture{
    case none // El yok
    case open // Açık El -> zıpla
    case fist // Yumrul -> çömel
    case pointLeft // Sola işaret -> soal git
    case pointRight // Sağa işaret -> sağa git
    case peace // Victory -> çift zıplama
}
// MARK: - Oyun Skoru
struct GameScore {
    var points : Int = 0
    var distance : Int = 0
    var coinsCollected: Int = 0
    var highScore : Int {
        get { UserDefaults.standard.integer(forKey: "highScore")}
        set{ UserDefaults.standard.set(newValue, forKey: "highScore")}
    }
    
    mutating func update(deltaTime: TimeInterval) {
        distance += 1
        points = distance + (coinsCollected * 10)
    }
    
    mutating func saveHighScore(){
        var score = self
        if points > highScore {
            score.highScore = points
        }
    }
}
// - Platform türleri
enum PlatformType{
    case normal // Normal Platform
    case moving // Hareket eden
    case breaking // Kırılan
    case spring // Zıplatan
}

// MARK: Fizik kategorileri
struct PhysicsCategory{
    static let none:       UInt32 = 0
    static let player:     UInt32 = 0b0001
    static let platform:   UInt32 = 0b0010
    static let coin:       UInt32 = 0b0100
    static let obstacle:   UInt32 = 0b1000
    static let ground:     UInt32 = 0b10000
}
