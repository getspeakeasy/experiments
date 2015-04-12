//
//  Phrase.swift
//  SpeakKit
//
//  Created by Levi McCallum on 9/7/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import Foundation

public class Phrase: Printable {
    var tokens: [Token] = []
    
    var nounScore: Double!
    var verbScore: Double!
    
    public init() {}
    
    var last: Token? {
        return tokens.last
    }
    
    var isEmpty: Bool {
        return last == nil
    }
    
    public var description: String {
        return "\(nounScore): \(nounQuery)"
    }
    
    public var nounQuery: String {
        var tokens = self.tokens.filter({ (token) -> Bool in
            return token.valuable
        })
            .map({ (token) -> String in
                return token.string
            })
            
            return " ".join(tokens)
    }
    
    public func add(token: Token) -> Bool {
        if token.invalid { return false }
        
        if incrementNounScore(token) {
            tokens.append(token)
            return true
        }
        
        return false
    }
    
    func incrementNounScore(token: Token) -> Bool {
        if nounScore == nil {
            nounScore = token.baseScore
            return true
        }
        
        if let tagScore = last?.nextTokenScore(token) {
            nounScore = nounScore + tagScore
            
            var firstChar = (token.string as NSString).substringToIndex(1)
            println("Query Builder: Sentence range location: \(token.sentenceRange.location)")
            if token.sentenceRange.location > 0 && firstChar == firstChar.uppercaseString {
                nounScore = nounScore + 0.1
            }
            
            return true
        }
        
        return false
    }
    
    public func finalizeScore() {
        // Sometimes a phrase is empty
        if nounScore == nil {
            return
        }
        
        println("Query Builder: Noun ratio: \(nounRatio)")
        if nounRatio <= 0.5 {
            nounScore = nounScore - 1.0
        }
    }
    
    var nounRatio: Double {
        var nouns = countForTag(NSLinguisticTagNoun) +
            countForTag(NSLinguisticTagPersonalName) +
            countForTag(NSLinguisticTagPlaceName) +
            countForTag(NSLinguisticTagOrganizationName)
            
            var predicates = countForTag(NSLinguisticTagVerb) + countForTag(NSLinguisticTagParticle)
            
            if predicates > 0 {
                return Double(nouns / predicates)
            } else {
                return Double(nouns)
            }
    }
    
    func countForTag(tag: NSString) -> Int {
        return countElements(tokens.filter({ (token) -> Bool in
            return token.tag == tag
        }))
    }
}
