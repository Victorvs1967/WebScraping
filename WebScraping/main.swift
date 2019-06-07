//
//  main.swift
//  WebScraping
//
//  Created by Victor Smirnov on 07/06/2019.
//  Copyright © 2019 Victor Smirnov. All rights reserved.
//

import Foundation

// Input parameters
//let startUrl = URL(string: "https://www.gutenberg.org/dirs/")!

let startUrl = URL(string: "https://www.vesti-ukr.com/")!
let wordToSearch = "гройс"
let maximumPagesToVisit = 25

// Crawler parameters
let semaphore = DispatchSemaphore(value: 0)
var visitedPages: Set<URL> = []
var pagesToVisit: Set<URL> = [startUrl]

var wordsNumber = 0

// Crawler core
func crawl() {
  
  guard visitedPages.count <= maximumPagesToVisit else {
    print("🏁 Reached max number of pages to visit")
    print("Found \(wordsNumber) words at \(visitedPages.count) pages...")
    semaphore.signal()
    return
  }
  
  guard let pageToVisit = pagesToVisit.popFirst() else {
    print("Found \(wordsNumber) words at \(visitedPages.count) pages...")
    print("🏁 No more page to visit")
    semaphore.signal()
    return
  }
  
  if visitedPages.contains(pageToVisit) {
    crawl()
  } else {
    visit(page: pageToVisit)
  }
}

func visit(page url: URL) {
  
  visitedPages.insert(url)
  
  let task = URLSession.shared.dataTask(with: url) { data, response, error in
    
    defer { crawl() }
    guard let data = data, error == nil, let document = String(data: data, encoding: .utf8) else { return }
    parse(document: document, url: url)
  }
  
  print("🔎 Visiting page: \(url)")
  task.resume()
}

func parse(document: String, url: URL) {
  
  func find(word: String) {
    
    let pattern = #"\#(word)\w*\s?"#
    //    let pattern = #"href=".*\.\#(word)""#
    
    let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    let matches = regex.matches(in: document, options: [.reportCompletion], range: NSRange(location: 0, length: document.count))
    
    for match in matches {
      wordsNumber += 1
      
      //      let txt = String((document as NSString).substring(with: match.range).dropFirst(6).dropLast())
      let txt = String((document as NSString).substring(with: match.range).dropLast())
      
      print("✅ Word \(txt) found at page \(url)")
    }
  }
  
  func collectLinks() -> [URL] {
    
    func getMatches(pattern: String, text: String) -> [String] {
      // used to remove 'href=' & '"' from the matches
      func trim(url: String) -> String {
        return String(url.dropFirst(6).dropLast())
      }
      
      let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let matches = regex.matches(in: text, options: [.reportCompletion], range: NSRange(location: 0, length: text.count))
      return matches.map { trim(url: (text as NSString).substring(with: $0.range)) }
    }
    
    let pattern = #"href="(http://.*?|https://.*?)""#
    let matches = getMatches(pattern: pattern, text: document)
    return matches.compactMap { URL(string: $0) }
  }
  
  find(word: wordToSearch)
  collectLinks().forEach { pagesToVisit.insert($0) }
  print("\(pagesToVisit.count) links at page \(url)")
}

crawl()
semaphore.wait()



