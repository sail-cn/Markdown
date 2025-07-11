//
//  MarkdownRenderer.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import SwiftUI

/// Markdown渲染器视图
struct MarkdownRenderer: View {
    let content: String
    let fileName: String
    
    init(content: String, fileName: String = "") {
        self.content = content
        self.fileName = fileName
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !fileName.isEmpty {
                    // 文件标题
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                        Text(fileName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                        .padding(.horizontal)
                }
                
                // 渲染Markdown内容
                MarkdownText(content)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// 简化的Markdown文本渲染器
struct MarkdownText: View {
    let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(content), id: \.id) { element in
                renderElement(element)
            }
        }
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case .header1:
            Text(element.content)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        case .header2:
            Text(element.content)
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        case .header3:
            Text(element.content)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        case .paragraph:
            Text(parseInlineMarkdown(element.content))
                .font(.body)
                .lineSpacing(4)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        case .bulletList:
            VStack(alignment: .leading, spacing: 4) {
                ForEach(element.listItems, id: \.self) { item in
                    HStack(alignment: .top) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text(parseInlineMarkdown(item))
                            .font(.body)
                        Spacer()
                    }
                }
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .numberedList:
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(element.listItems.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text(parseInlineMarkdown(item))
                            .font(.body)
                        Spacer()
                    }
                }
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .codeBlock:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(NSColor.controlColor))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        case .quote:
            HStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                Text(element.content)
                    .font(.body)
                    .italic()
                    .padding(.leading, 8)
                Spacer()
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .horizontalRule:
            Divider()
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // 处理粗体 **text**
        let boldPattern = "\\*\\*(.*?)\\*\\*"
        if let boldRegex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = boldRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let boldText = String(text[range])
                    let content = String(boldText.dropFirst(2).dropLast(2))
                    
                    // 安全地处理 AttributedString 范围
                    if let startIndex = attributedString.characters.index(attributedString.startIndex, offsetBy: match.range.location, limitedBy: attributedString.endIndex),
                       let endIndex = attributedString.characters.index(startIndex, offsetBy: match.range.length, limitedBy: attributedString.endIndex) {
                        let attributedRange = startIndex..<endIndex
                        var replacement = AttributedString(content)
                        replacement.font = .body.bold()
                        attributedString.replaceSubrange(attributedRange, with: replacement)
                    }
                }
            }
        }
        
        // 处理斜体 *text* (但不匹配已经处理过的粗体)
        let italicPattern = "(?<!\\*)\\*([^*]+)\\*(?!\\*)"
        if let italicRegex = try? NSRegularExpression(pattern: italicPattern) {
            let currentText = String(attributedString.characters)
            let matches = italicRegex.matches(in: currentText, range: NSRange(currentText.startIndex..., in: currentText))
            for match in matches.reversed() {
                if let range = Range(match.range, in: currentText) {
                    let italicText = String(currentText[range])
                    let content = String(italicText.dropFirst(1).dropLast(1))
                    
                    // 安全地处理 AttributedString 范围
                    if let startIndex = attributedString.characters.index(attributedString.startIndex, offsetBy: match.range.location, limitedBy: attributedString.endIndex),
                       let endIndex = attributedString.characters.index(startIndex, offsetBy: match.range.length, limitedBy: attributedString.endIndex) {
                        let attributedRange = startIndex..<endIndex
                        var replacement = AttributedString(content)
                        replacement.font = .body.italic()
                        attributedString.replaceSubrange(attributedRange, with: replacement)
                    }
                }
            }
        }
        
        // 处理行内代码 `code`
        let codePattern = "`(.*?)`"
        if let codeRegex = try? NSRegularExpression(pattern: codePattern) {
            let currentText = String(attributedString.characters)
            let matches = codeRegex.matches(in: currentText, range: NSRange(currentText.startIndex..., in: currentText))
            for match in matches.reversed() {
                if let range = Range(match.range, in: currentText) {
                    let codeText = String(currentText[range])
                    let content = String(codeText.dropFirst(1).dropLast(1))
                    
                    // 安全地处理 AttributedString 范围
                    if let startIndex = attributedString.characters.index(attributedString.startIndex, offsetBy: match.range.location, limitedBy: attributedString.endIndex),
                       let endIndex = attributedString.characters.index(startIndex, offsetBy: match.range.length, limitedBy: attributedString.endIndex) {
                        let attributedRange = startIndex..<endIndex
                        var replacement = AttributedString(content)
                        replacement.font = .body.monospaced()
                        replacement.backgroundColor = .init(NSColor.controlColor)
                        attributedString.replaceSubrange(attributedRange, with: replacement)
                    }
                }
            }
        }
        
        return attributedString
    }
}

// MARK: - Markdown解析器
private func parseMarkdown(_ content: String) -> [MarkdownElement] {
    var elements: [MarkdownElement] = []
    let lines = content.components(separatedBy: .newlines)
    var i = 0
    
    while i < lines.count {
        let line = lines[i].trimmingCharacters(in: .whitespaces)
        
        if line.isEmpty {
            i += 1
            continue
        }
        
        // 标题
        if line.hasPrefix("# ") {
            elements.append(MarkdownElement(type: .header1, content: String(line.dropFirst(2))))
        } else if line.hasPrefix("## ") {
            elements.append(MarkdownElement(type: .header2, content: String(line.dropFirst(3))))
        } else if line.hasPrefix("### ") {
            elements.append(MarkdownElement(type: .header3, content: String(line.dropFirst(4))))
        }
        // 水平线
        else if line == "---" || line == "***" {
            elements.append(MarkdownElement(type: .horizontalRule, content: ""))
        }
        // 代码块
        else if line.hasPrefix("```") {
            i += 1
            var codeLines: [String] = []
            while i < lines.count && !lines[i].hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            elements.append(MarkdownElement(type: .codeBlock, content: codeLines.joined(separator: "\n")))
        }
        // 引用
        else if line.hasPrefix("> ") {
            elements.append(MarkdownElement(type: .quote, content: String(line.dropFirst(2))))
        }
        // 无序列表
        else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            var listItems: [String] = []
            var j = i
            while j < lines.count {
                let currentLine = lines[j].trimmingCharacters(in: .whitespaces)
                if currentLine.hasPrefix("- ") || currentLine.hasPrefix("* ") {
                    listItems.append(String(currentLine.dropFirst(2)))
                    j += 1
                } else if currentLine.isEmpty {
                    j += 1
                } else {
                    break
                }
            }
            elements.append(MarkdownElement(type: .bulletList, content: "", listItems: listItems))
            i = j - 1
        }
        // 有序列表
        else if line.matches("^\\d+\\. ") {
            var listItems: [String] = []
            var j = i
            while j < lines.count {
                let currentLine = lines[j].trimmingCharacters(in: .whitespaces)
                if currentLine.matches("^\\d+\\. ") {
                    let content = currentLine.replacingOccurrences(of: "^\\d+\\. ", with: "", options: .regularExpression)
                    listItems.append(content)
                    j += 1
                } else if currentLine.isEmpty {
                    j += 1
                } else {
                    break
                }
            }
            elements.append(MarkdownElement(type: .numberedList, content: "", listItems: listItems))
            i = j - 1
        }
        // 普通段落
        else {
            elements.append(MarkdownElement(type: .paragraph, content: line))
        }
        
        i += 1
    }
    
    return elements
}

// MARK: - 数据模型
private struct MarkdownElement {
    let id = UUID()
    let type: MarkdownElementType
    let content: String
    let listItems: [String]
    
    init(type: MarkdownElementType, content: String, listItems: [String] = []) {
        self.type = type
        self.content = content
        self.listItems = listItems
    }
}

private enum MarkdownElementType {
    case header1, header2, header3
    case paragraph
    case bulletList, numberedList
    case codeBlock
    case quote
    case horizontalRule
}

// MARK: - String扩展
private extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
} 