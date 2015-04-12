//
//  Token.swift
//  SpeakKit
//
//  Created by Levi McCallum on 9/7/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import Foundation

public class Token: Printable {
    
    public var string: String
    public var tag: NSString
    public var sentenceRange: NSRange
    
    public var baseScore: Double {
        return 0.0
    }
    
    public var children: [NSString: Double] {
        return [:]
    }
    
    public var description: String {
        return "\(string) (\(tag))"
    }
    
    public var valuable: Bool {
        if tag == NSLinguisticTagDeterminer || tag == NSLinguisticTagParticle {
            return false
            }
            
            return true
    }
    
    public var invalid: Bool {
        if wordIgnored { return true }
            if (string as NSString).rangeOfString("'").location != NSNotFound {
                return true
            }
            //        if (string as NSString).containsString("'") { return true }
            return false
    }
    
    var wordIgnored: Bool {
        let ignoredWords = [
            "second": true,
            "minute": true,
            "hour": true,
            "week": true,
            "month": true,
            "year": true,
            "time": true,
            ]
            return ignoredWords[string] ?? false
    }
    
    public required init(string: String, tag: NSString, rangeInSentence sentenceRange: NSRange) {
        self.string = string
        self.tag = tag
        self.sentenceRange = sentenceRange
    }
    
    public class func tokenWith(string: String, tag: NSString, rangeInSentence sentenceRange: NSRange) -> Token {
        var classType: Token.Type
        
        switch tag {
        case NSLinguisticTagDeterminer:
            classType = DeterminerToken.self
        case NSLinguisticTagAdjective:
            classType = AdjectiveToken.self
        case NSLinguisticTagNoun,
        NSLinguisticTagPersonalName,
        NSLinguisticTagPlaceName,
        NSLinguisticTagOrganizationName,
        NSLinguisticTagOtherWord:
            classType = NounToken.self
        case NSLinguisticTagVerb:
            classType = VerbToken.self
        case NSLinguisticTagParticle:
            classType = ParticleToken.self
        default:
            classType = self
        }
        
        return classType(string: string, tag: tag, rangeInSentence: sentenceRange)
    }
    
    public func nextTokenScore(token: Token) -> Double? {
        return self.children[token.tag]
    }
    
}

class DeterminerToken: Token {
    override var baseScore: Double {
        return 0.1
    }
    
    override var children: [NSString: Double] {
        return [
            NSLinguisticTagNoun: 1.0,
            NSLinguisticTagPlaceName: 2.0,
            NSLinguisticTagOtherWord: 1.0,
            NSLinguisticTagOrganizationName: 2.0,
            NSLinguisticTagPersonalName: 2.0,
            NSLinguisticTagAdjective: 0.1,
            ]
    }
}

class AdjectiveToken: Token {
    override var children: [NSString: Double] {
        return [
            NSLinguisticTagAdjective: 0.1,
            NSLinguisticTagNoun: 1.0,
            NSLinguisticTagOtherWord: 1.0,
            NSLinguisticTagPlaceName: 2.0,
            NSLinguisticTagOrganizationName: 2.0,
            NSLinguisticTagPersonalName: 2.0,
            ]
    }
}

class NounToken: Token {
    override var baseScore: Double {
        switch tag {
        case NSLinguisticTagPersonalName,
        NSLinguisticTagPlaceName,
        NSLinguisticTagOrganizationName:
            return 2.0
        default:
            return 1.0
            }
    }
    
    override var children: [NSString: Double] {
        return [
            NSLinguisticTagNoun: 1.0,
            NSLinguisticTagPlaceName: 2.0,
            NSLinguisticTagOtherWord: 1.0,
            NSLinguisticTagOrganizationName: 2.0,
            NSLinguisticTagPersonalName: 2.0,
            NSLinguisticTagParticle: 0.1,
            ]
    }
}

class VerbToken: Token {
    override var children: [NSString: Double] {
        return [
            NSLinguisticTagDeterminer: 0.1,
            NSLinguisticTagParticle: 0.1,
            NSLinguisticTagPronoun: 0.1,
            ]
    }
}

class ParticleToken: Token {
    override var children: [NSString: Double] {
        return [
            NSLinguisticTagVerb: 0.1,
            NSLinguisticTagNoun: 1.0,
            NSLinguisticTagPlaceName: 2.0,
            NSLinguisticTagOtherWord: 1.0,
            NSLinguisticTagOrganizationName: 2.0,
            NSLinguisticTagPersonalName: 2.0,
            ]
    }
}
