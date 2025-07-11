//
//  MarkdownDetailView.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import SwiftUI

/// Markdown详情视图
struct MarkdownDetailView: View {
    let fileItem: FileItem
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("正在加载...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else {
                    MarkdownRenderer(content: content, fileName: fileItem.name)
                }
            }
            .navigationTitle(fileItem.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("分享文件") {
                            shareFile()
                        }
                        
                        Button("复制内容") {
                            copyContent()
                        }
                        
                        Button("显示文件信息") {
                            showFileInfo()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            loadFileContent()
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text("加载失败")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                loadFileContent()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func loadFileContent() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOf: fileItem.url, encoding: .utf8)
                
                DispatchQueue.main.async {
                    self.content = fileContent
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "无法读取文件内容：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func shareFile() {
        #if os(macOS)
        let sharingServicePicker = NSSharingServicePicker(items: [fileItem.url])
        if let button = NSApp.mainWindow?.contentView?.subviews.first {
            sharingServicePicker.show(relativeTo: .zero, of: button, preferredEdge: .minY)
        }
        #endif
    }
    
    private func copyContent() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #else
        UIPasteboard.general.string = content
        #endif
        
        alertMessage = "文件内容已复制到剪贴板"
        showingAlert = true
    }
    
    private func showFileInfo() {
        let info = """
        文件名：\(fileItem.name)
        大小：\(fileItem.formattedSize)
        修改时间：\(fileItem.formattedDate)
        路径：\(fileItem.url.path)
        """
        
        alertMessage = info
        showingAlert = true
    }
}

#Preview {
    MarkdownDetailView(fileItem: FileItem(url: URL(fileURLWithPath: "/tmp/test.md")))
} 