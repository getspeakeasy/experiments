//
//  TagEnumerator.swift
//  SpeakKit
//
//  Created by Levi McCallum on 9/7/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import Foundation

public class TagEnumerator {
    
    var input: String
    
    var phrases: [Phrase] = []
    var nounCandidates: [Phrase] = []
    
    var phrase: Phrase!
    var currentSentence: NSRange = NSRange(location: NSNotFound, length: 0)
    
    var previousToken: Token? {
        return phrase.last
    }
    
    public var block: (String!, NSRange, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void {
        return { tag, tokenRange, sentenceRange, stop in
            self.enumerateTag(tag, tokenRange: tokenRange, sentenceRange: sentenceRange, stop: stop)
            }
    }
    
    public var queries: [String] {
        sort(&nounCandidates) { $0.nounScore > $1.nounScore }
            return nounCandidates.map { $0.nounQuery }
    }
    
    init(input: String) {
        self.input = input
        phrase = Phrase()
    }
    
    func enumerateTag(tag: String!, tokenRange: NSRange, sentenceRange: NSRange, stop: UnsafeMutablePointer<ObjCBool>) {
        let token = tokenWithWordRange(tokenRange, sentenceRange: sentenceRange, tag: tag)
        
        //        println("Query Builder: Raw token: \(token)")
        
        if currentSentence.location == NSNotFound {
            currentSentence = sentenceRange
        }
        
        if phrase.isEmpty {
            phrase.add(token)
            return
        }
        
        if sentenceChanged(sentenceRange) {
            completePhrase(token)
            currentSentence = sentenceRange
        }
        
        if phrase.add(token) == false {
            // create new phrase
            // leaf node in pattern match, create a new phrase
            completePhrase(token)
        }
        
        if endOfSentence(tokenRange) {
            completePhrase(token)
        }
    }
    
    func completePhrase(token: Token) {
        phrase.finalizeScore()
        if phrase.nounScore >= 1.0 {
            nounCandidates.append(phrase)
        }
        phrases.append(phrase)
        
        //        println("Query Builder: Phrase: \(phrase)")
        
        phrase = Phrase()
        phrase.add(token)
    }
    
    func tokenWithWordRange(range: NSRange, sentenceRange: NSRange, tag: NSString!) -> Token {
        let word = wordWithRange(range)
        let rangeInSentence = NSIntersectionRange(range, sentenceRange)
        //        println("Query Builder: Range in sentence: \(rangeInSentence)")
        return Token.tokenWith(word, tag: tag, rangeInSentence: rangeInSentence)
    }
    
    func sentenceWithRange(range: NSRange) -> String {
        return (input as NSString).substringWithRange(range) as String
    }
    
    func wordWithRange(range: NSRange) -> String {
        return (input as NSString).substringWithRange(range) as String
    }
    
    func sentenceChanged(range: NSRange) -> Bool {
        return currentSentence.location != range.location
    }
    
    func endOfSentence(range: NSRange) -> Bool {
        return NSMaxRange(range) == NSMaxRange(currentSentence)
    }
    
}