//
//  QueryBuilder.swift
//  ImageSearch
//
//  Created by Levi McCallum on 8/31/14.
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

public class Phrase: Printable {
    var tokens: [Token] = []

    var nounScore: Double!
    var verbScore: Double!
    
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

public class QueryBuilder {

    let tagger: NSLinguisticTagger!
    
    var enumerator: TagEnumerator!

    public var string: String = "" {
        didSet {
            enumerator = TagEnumerator(input: string)
            tagger.string = string
        }
    }
    
    var range: NSRange {
        return NSRange(location: 0, length: countElements(string))
    }
    
    var options: NSLinguisticTaggerOptions {
        return NSLinguisticTaggerOptions.OmitWhitespace | NSLinguisticTaggerOptions.JoinNames
    }

    init() {
        let schemes = NSLinguisticTagger.availableTagSchemesForLanguage("en")
        let options = Int(self.options.toRaw())
        tagger = NSLinguisticTagger(tagSchemes: schemes, options: options)
    }
    
    public func keywordsForThought(input: String) -> [String] {
        string = input
        tagger.enumerateTagsInRange(range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass,
                                           options: options,
                                           usingBlock: enumerator.block)

        return enumerator.queries
    }
    
}
