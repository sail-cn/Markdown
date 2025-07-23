//
//  MarkdownApp.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import SwiftUI

@main
struct MarkdownApp: App {
    @StateObject private var documentHandler = DocumentHandler()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentHandler)
                .onOpenURL { url in
                    documentHandler.handleOpenURL(url)
                }
        }
        .handlesExternalEvents(matching: ["*"])
    }
}

// 文档处理器
class DocumentHandler: ObservableObject {
    @Published var pendingFileURL: URL?
    @Published var securityScopedURLs: [URL] = []
    
    func handleOpenURL(_ url: URL) {
        // 检查是否为Markdown文件
        if FileManager.default.isMarkdownFile(url) {
            pendingFileURL = url
            
            // 在沙盒环境下，我们需要开始访问安全范围的资源
            if url.startAccessingSecurityScopedResource() {
                securityScopedURLs.append(url)
            }
            
            // 保存到历史记录
            FileManager.default.saveLastOpenedFile(url)
            FileManager.default.addToExternalFileHistory(url)
        }
    }
    
    func clearPendingFile() {
        pendingFileURL = nil
    }
    
    func stopAccessingSecurityScopedResource(for url: URL) {
        if let index = securityScopedURLs.firstIndex(of: url) {
            url.stopAccessingSecurityScopedResource()
            securityScopedURLs.remove(at: index)
        }
    }
    
    deinit {
        // 清理所有安全范围的URL访问
        for url in securityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
