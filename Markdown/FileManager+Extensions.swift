//
//  FileManager+Extensions.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import Foundation

extension FileManager {
    /// 获取应用的Documents目录
    var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory,
                                             in: .userDomainMask)
        return paths[0]
    }
    
    /// 获取指定目录下的所有文件
    func contentsOfDirectory(at url: URL) -> [URL] {
        do {
            let contents = try contentsOfDirectory(at: url,
                                                 includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                                                 options: [.skipsHiddenFiles])
            return contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            print("Error reading directory: \(error)")
            return []
        }
    }
    
    /// 检查文件是否为markdown文件
    func isMarkdownFile(_ url: URL) -> Bool {
        let markdownExtensions = ["md", "markdown", "mdown", "mkdn", "mkd"]
        return markdownExtensions.contains(url.pathExtension.lowercased())
    }
    
    /// 创建示例markdown文件
    func createSampleMarkdownFiles() {
        let sampleFiles = [
            ("Welcome.md", sampleWelcomeContent),
            ("README.md", sampleReadmeContent),
            ("Features.md", sampleFeaturesContent)
        ]
        
        for (filename, content) in sampleFiles {
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            if !fileExists(atPath: fileURL.path) {
                try? content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - 示例内容
private let sampleWelcomeContent = """
# 欢迎使用 Markdown 浏览器

这是一个功能强大的Markdown文件浏览器应用！

## 功能特色

- 📁 浏览文档目录中的所有文件
- 📄 支持多种Markdown文件格式（.md, .markdown, .mdown等）
- 🎨 美观的UI设计
- 📱 原生iOS应用体验

## 使用说明

1. 在文件列表中选择任意Markdown文件
2. 应用会自动渲染并显示文件内容
3. 支持所有标准Markdown语法

**祝您使用愉快！**
"""

private let sampleReadmeContent = """
# Markdown Browser

这是一个为iOS平台开发的Markdown文件浏览器。

## 技术栈

- SwiftUI
- iOS 15.0+
- FileManager API

## 支持的文件格式

- `.md`
- `.markdown`
- `.mdown`
- `.mkdn`
- `.mkd`

## 开发信息

开发者：Yanxi Feng  
创建时间：2025年7月10日
"""

private let sampleFeaturesContent = """
# 功能详情

## 核心功能

### 1. 文件浏览
- 自动扫描Documents目录
- 过滤显示Markdown文件
- 支持文件夹导航

### 2. 内容渲染
- 支持标准Markdown语法
- 实时内容更新
- 响应式布局

### 3. 用户界面
- 现代化设计
- 直观的操作体验
- 支持深色模式

## 待实现功能

- [ ] 文件搜索
- [ ] 文件编辑
- [ ] 导出功能
- [ ] 云同步支持

---

*更多功能正在开发中...*
""" 