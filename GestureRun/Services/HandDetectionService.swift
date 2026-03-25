//
//  HandDetectionService.swift
//  GestureRun
//
//  Created by Baran on 25.03.2026.
//

import Vision
import AVFoundation
import Combine

final class HandDetectionService {
    
    // Her frame'de tespit edilen el pozisyonunu yayar
    let handPublisher = PassthroughSubject<HandPosition, Never>()
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private let requestHandler = VNSequenceRequestHandler()
    
    // MARK: - Init
    init() {
        handPoseRequest.maximumHandCount = 1
    }
    
    // MARK: - Frame işleme
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        do {
            try requestHandler.perform(
                [handPoseRequest],
                on: sampleBuffer,
                orientation: .leftMirrored
            )
            guard let observation = handPoseRequest.results?.first else {
                handPublisher.send(.empty)
                return
            }
            let position = try analyzeHand(observation)
            handPublisher.send(position)
        } catch {
            handPublisher.send(.empty)
        }
    }
    
    // MARK: - El analizi
    private func analyzeHand(_ observation: VNHumanHandPoseObservation) throws -> HandPosition {
        
        // Parmak uçlarını al
        let thumbTip   = try observation.recognizedPoint(.thumbTip)
        let indexTip   = try observation.recognizedPoint(.indexTip)
        let middleTip  = try observation.recognizedPoint(.middleTip)
        let ringTip    = try observation.recognizedPoint(.ringTip)
        let littleTip  = try observation.recognizedPoint(.littleTip)
        
        // MCP (yumruk tabanı) noktaları
        let indexMCP   = try observation.recognizedPoint(.indexMCP)
        let middleMCP  = try observation.recognizedPoint(.middleMCP)
        let ringMCP    = try observation.recognizedPoint(.ringMCP)
        let littleMCP  = try observation.recognizedPoint(.littleMCP)
        
        // El merkezi (bilek)
        let wrist      = try observation.recognizedPoint(.wrist)
        
        // Ortalama güven skoru
        let confidence = (thumbTip.confidence + indexTip.confidence +
                         middleTip.confidence + ringTip.confidence) / 4
        
        // Parmakların açık olup olmadığını kontrol et
        let indexOpen  = indexTip.location.y  > indexMCP.location.y
        let middleOpen = middleTip.location.y > middleMCP.location.y
        let ringOpen   = ringTip.location.y   > ringMCP.location.y
        let littleOpen = littleTip.location.y > littleMCP.location.y
        
        let openCount = [indexOpen, middleOpen, ringOpen, littleOpen]
            .filter { $0 }.count
        
        // Hareket tespiti
        let gesture = detectGesture(
            thumbTip: thumbTip,
            indexTip: indexTip,
            middleTip: middleTip,
            openCount: openCount,
            indexOpen: indexOpen,
            middleOpen: middleOpen,
            ringOpen: ringOpen,
            littleOpen: littleOpen,
            wrist: wrist
        )
        
        return HandPosition(
            gesture: gesture,
            normalizedX: wrist.location.x,
            normalizedY: 1 - wrist.location.y,
            confidence: confidence
        )
    }
    
    // MARK: - Hareket tanıma
    private func detectGesture(
        thumbTip: VNRecognizedPoint,
        indexTip: VNRecognizedPoint,
        middleTip: VNRecognizedPoint,
        openCount: Int,
        indexOpen: Bool,
        middleOpen: Bool,
        ringOpen: Bool,
        littleOpen: Bool,
        wrist: VNRecognizedPoint
    ) -> HandGesture {
        
        // Açık el → 4 parmak açık → ZIPLA
        if openCount >= 3 {
            return .open
        }
        
        // Yumruk → hiç parmak açık değil → ÇÖMEL
        if openCount == 0 {
            return .fist
        }
        
        // Victory (✌️) → sadece işaret ve orta açık → ÇİFT ZIPLA
        if indexOpen && middleOpen && !ringOpen && !littleOpen {
            return .peace
        }
        
        // İşaret sola → sola git
        if indexOpen && !middleOpen && !ringOpen && !littleOpen {
            let direction = indexTip.location.x - wrist.location.x
            return direction < 0 ? .pointLeft : .pointRight
        }
        
        return .none
    }
}
