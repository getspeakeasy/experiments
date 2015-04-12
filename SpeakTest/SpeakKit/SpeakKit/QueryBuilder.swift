//
//  QueryBuilder.swift
//  ImageSearch
//
//  Created by Levi McCallum on 8/31/14.
//  Copyright (c) 2014 Speakeasy. All rights reserved.
//

import Foundation

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
