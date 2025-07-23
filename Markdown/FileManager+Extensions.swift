//
//  FileManager+Extensions.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import Foundation

// MARK: - UserDefaults Keys
private enum UserDefaultsKeys {
    static let lastOpenedFilePath = "lastOpenedFilePath"
    static let lastOpenedFileBookmark = "lastOpenedFileBookmark"
    static let externalFileHistory = "externalFileHistory"
    static let externalFileBookmarks = "externalFileBookmarks"
}

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
    
    // MARK: - 文件历史记录
    
    /// 保存最后打开的文件路径
    func saveLastOpenedFile(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: UserDefaultsKeys.lastOpenedFilePath)
        
        // 如果是外部文件，保存Security-Scoped Bookmark
        if !url.path.hasPrefix(documentsDirectory.path) {
            do {
                let bookmarkData = try url.bookmarkData(options: .withSecurityScope)
                UserDefaults.standard.set(bookmarkData, forKey: UserDefaultsKeys.lastOpenedFileBookmark)
            } catch {
                print("Failed to create bookmark for last opened file: \(error)")
            }
        } else {
            // 内部文件不需要bookmark
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastOpenedFileBookmark)
        }
    }
    
    /// 获取最后打开的文件路径
    func getLastOpenedFilePath() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.lastOpenedFilePath)
    }
    
    /// 获取最后打开文件的安全范围URL
    func getLastOpenedFileURL() -> URL? {
        guard let filePath = getLastOpenedFilePath() else { return nil }
        
        // 如果是内部文件，直接返回URL
        if filePath.hasPrefix(documentsDirectory.path) {
            return URL(fileURLWithPath: filePath)
        }
        
        // 如果是外部文件，尝试从bookmark恢复
        guard let bookmarkData = UserDefaults.standard.data(forKey: UserDefaultsKeys.lastOpenedFileBookmark) else {
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark is stale for last opened file")
                // 可以尝试重新创建bookmark
            }
            
            return url
        } catch {
            print("Failed to resolve bookmark for last opened file: \(error)")
            return nil
        }
    }
    
    /// 添加外部文件到历史记录
    func addToExternalFileHistory(_ url: URL) {
        var history = getExternalFileHistory()
        let filePath = url.path
        
        // 移除重复项
        history.removeAll { $0 == filePath }
        
        // 添加到开头
        history.insert(filePath, at: 0)
        
        // 限制历史记录数量（最多10个）
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        
        UserDefaults.standard.set(history, forKey: UserDefaultsKeys.externalFileHistory)
    }
    
    /// 获取外部文件历史记录
    func getExternalFileHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.externalFileHistory) ?? []
    }
    
    /// 清理无效的历史记录（文件不存在的）
    func cleanupExternalFileHistory() {
        let history = getExternalFileHistory()
        let validPaths = history.filter { fileExists(atPath: $0) }
        UserDefaults.standard.set(validPaths, forKey: UserDefaultsKeys.externalFileHistory)
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