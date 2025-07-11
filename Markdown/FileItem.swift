//
//  FileItem.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import Foundation

/// 文件项模型
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        // 获取文件属性
        let resourceValues = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey
        ])
        
        self.isDirectory = resourceValues?.isDirectory ?? false
        self.size = Int64(resourceValues?.fileSize ?? 0)
        self.modificationDate = resourceValues?.contentModificationDate ?? Date()
    }
    
    /// 是否为Markdown文件
    var isMarkdownFile: Bool {
        return FileManager.default.isMarkdownFile(url)
    }
    
    /// 格式化文件大小
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /// 格式化修改时间
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
    
    /// 文件图标名称
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        } else if isMarkdownFile {
            return "doc.text.fill"
        } else {
            return "doc.fill"
        }
    }
    
    /// 文件图标颜色
    var iconColor: String {
        if isDirectory {
            return "blue"
        } else if isMarkdownFile {
            return "green"
        } else {
            return "gray"
        }
    }
}

// MARK: - Hashable
extension FileItem {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        return lhs.url == rhs.url
    }
} 