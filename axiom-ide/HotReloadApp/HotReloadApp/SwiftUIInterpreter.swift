import SwiftUI
import Foundation

struct ExtractedButton: Sendable {
    let title: String
    let color: Color
}

struct ExtractedText: Sendable {
    let content: String
    let font: Font
    let color: Color
}

class SwiftUIInterpreter {
    let sourceCode: String
    
    init(sourceCode: String) {
        self.sourceCode = sourceCode
    }
    
    // Extract main title (usually .largeTitle or .title)
    var extractedTitle: String? {
        // Look for Text with large fonts - more flexible pattern
        let patterns = [
            #"Text\("([^"]+)"\)[^}]*\.font\(\.largeTitle\)"#,
            #"Text\("([^"]+)"\)[^}]*\.font\(\.title\)"#,
            #"Text\("([^"]+)"\)[^}]*\.font\(\.title2\)"#
        ]
        
        for pattern in patterns {
            if let match = sourceCode.range(of: pattern, options: .regularExpression) {
                let matchedText = String(sourceCode[match])
                if let titleMatch = matchedText.range(of: #"Text\("([^"]+)"\)"#, options: .regularExpression) {
                    let fullMatch = String(matchedText[titleMatch])
                    if let textContent = fullMatch.range(of: #""([^"]+)""#, options: .regularExpression) {
                        let title = String(fullMatch[textContent])
                        return title.replacingOccurrences(of: "\"", with: "")
                    }
                }
            }
        }
        
        // Fallback: Look for first Text element that doesn't contain variables
        let fallbackPattern = #"Text\("([^"]+)"\)"#
        let matches = sourceCode.ranges(of: fallbackPattern, options: .regularExpression)
        
        for match in matches {
            let matchedText = String(sourceCode[match])
            if let titleMatch = matchedText.range(of: #""([^"]+)""#, options: .regularExpression) {
                let title = String(matchedText[titleMatch])
                let cleanTitle = title.replacingOccurrences(of: "\"", with: "")
                // Only return if it looks like a title (not too long, not a variable)
                if cleanTitle.count < 80 && !cleanTitle.contains("\\(") {
                    return cleanTitle
                }
            }
        }
        
        return nil
    }
    
    // Extract subtitle
    var extractedSubtitle: String? {
        // Look for Text with variable content (contains \() pattern)
        let variablePattern = #"Text\("([^"]*\\[^"]*\\([^"]*\\)[^"]*)"\)"#
        if let match = sourceCode.range(of: variablePattern, options: .regularExpression) {
            let matchedText = String(sourceCode[match])
            if let titleMatch = matchedText.range(of: #""([^"]+)""#, options: .regularExpression) {
                let title = String(matchedText[titleMatch])
                return title.replacingOccurrences(of: "\"", with: "")
            }
        }
        
        // Look for second Text element if no variable pattern found
        let allTextPattern = #"Text\("([^"]+)"\)"#
        let matches = sourceCode.ranges(of: allTextPattern, options: .regularExpression)
        
        if matches.count >= 2 {
            let secondMatch = matches[1]
            let matchedText = String(sourceCode[secondMatch])
            if let titleMatch = matchedText.range(of: #""([^"]+)""#, options: .regularExpression) {
                let title = String(matchedText[titleMatch])
                let cleanTitle = title.replacingOccurrences(of: "\"", with: "")
                if !cleanTitle.contains("Real-time") && !cleanTitle.contains("amazing") {
                    return cleanTitle
                }
            }
        }
        
        return nil
    }
    
    // Extract title color
    var extractedTitleColor: Color {
        if sourceCode.contains(".foregroundColor(.blue)") {
            return .blue
        } else if sourceCode.contains(".foregroundColor(.red)") {
            return .red
        } else if sourceCode.contains(".foregroundColor(.green)") {
            return .green
        } else if sourceCode.contains(".foregroundColor(.orange)") {
            return .orange
        } else if sourceCode.contains(".foregroundColor(.purple)") {
            return .purple
        }
        return .primary
    }
    
    // Extract subtitle color
    var extractedSubtitleColor: Color {
        // Look for color after the second Text element
        let allTextPattern = #"Text\("([^"]+)"\)[^}]*\.foregroundColor\(\.([^)]+)\)"#
        let matches = sourceCode.ranges(of: allTextPattern, options: .regularExpression)
        
        if matches.count >= 2 {
            let secondMatch = matches[1]
            let matchedText = String(sourceCode[secondMatch])
            if matchedText.contains(".foregroundColor(.red)") {
                return .red
            } else if matchedText.contains(".foregroundColor(.blue)") {
                return .blue
            } else if matchedText.contains(".foregroundColor(.green)") {
                return .green
            } else if matchedText.contains(".foregroundColor(.purple)") {
                return .purple
            } else if matchedText.contains(".foregroundColor(.orange)") {
                return .orange
            }
        }
        
        return .secondary
    }
    
    // Extract buttons
    var extractedButtons: [ExtractedButton] {
        var buttons: [ExtractedButton] = []
        
        // Look for Button patterns
        let buttonPattern = #"Button\("([^"]+)"\)"#
        let matches = sourceCode.ranges(of: buttonPattern, options: .regularExpression)
        
        for match in matches {
            let matchedText = String(sourceCode[match])
            if let titleMatch = matchedText.range(of: #""([^"]+)""#, options: .regularExpression) {
                let title = String(matchedText[titleMatch])
                let cleanTitle = title.replacingOccurrences(of: "\"", with: "")
                
                // Determine button color based on context
                let color: Color = {
                    if sourceCode.contains(".buttonStyle(.borderedProminent)") {
                        return .accentColor
                    } else if cleanTitle.lowercased().contains("increment") {
                        return .blue
                    } else if cleanTitle.lowercased().contains("decrement") {
                        return .red
                    }
                    return .primary
                }()
                
                buttons.append(ExtractedButton(title: cleanTitle, color: color))
            }
        }
        
        return buttons
    }
    
    // Extract additional text elements
    var extractedTexts: [ExtractedText] {
        var texts: [ExtractedText] = []
        
        // Look for descriptive text (usually .caption or smaller)
        let textPattern = #"Text\("([^"]+)"\)\s*\.font\(\.caption\)"#
        let matches = sourceCode.ranges(of: textPattern, options: .regularExpression)
        
        for match in matches {
            let matchedText = String(sourceCode[match])
            if let contentMatch = matchedText.range(of: #""([^"]+)""#, options: .regularExpression) {
                let content = String(matchedText[contentMatch])
                let cleanContent = content.replacingOccurrences(of: "\"", with: "")
                
                texts.append(ExtractedText(
                    content: cleanContent,
                    font: .caption,
                    color: .secondary
                ))
            }
        }
        
        return texts
    }
}

extension String {
    func ranges(of string: String, options: CompareOptions = []) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = startIndex..<endIndex
        
        while let range = range(of: string, options: options, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<endIndex
        }
        
        return ranges
    }
}