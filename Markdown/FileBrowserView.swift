//
//  FileBrowserView.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import SwiftUI
import UniformTypeIdentifiers

/// 文件浏览器视图
struct FileBrowserView: View {
    @State private var fileItems: [FileItem] = []
    @State private var currentDirectory: URL
    @State private var selectedFile: FileItem?
    @State private var showingMarkdownFile = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    @State private var openedExternalFile: FileItem?
    @EnvironmentObject var documentHandler: DocumentHandler
    
    init(directory: URL = FileManager.default.documentsDirectory) {
        self._currentDirectory = State(initialValue: directory)
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            VStack {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if fileItems.isEmpty {
                    emptyStateView
                } else {
                    fileListView
                }
            }
            .navigationTitle("文件浏览器")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // 历史记录菜单
                    Menu {
                        let history = FileManager.default.getExternalFileHistory()
                        if history.isEmpty {
                            Text("暂无历史记录")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(Array(history.enumerated()), id: \.offset) { index, filePath in
                                if FileManager.default.fileExists(atPath: filePath) {
                                    Button(action: {
                                        openRecentFile(filePath)
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.text")
                                            Text(URL(fileURLWithPath: filePath).lastPathComponent)
                                        }
                                    }
                                }
                            }
                            
                            if !history.isEmpty {
                                Divider()
                                Button("清除历史记录") {
                                    UserDefaults.standard.removeObject(forKey: "externalFileHistory")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .help("最近打开的文件")
                    
                    Button("打开文件") {
                        openFileFromSystem()
                    }
                    .help("从系统中选择一个 Markdown 文件")
                    
                    Button("刷新") {
                        loadFiles()
                    }
                    .help("刷新当前目录")
                }
            }
            .onAppear {
                setupInitialFiles()
                loadFiles()
                loadFeaturesFile()
            }
            .onChange(of: documentHandler.pendingFileURL) { _, newURL in
                if let url = newURL {
                    handleExternalFile(url)
                    documentHandler.clearPendingFile()
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        } detail: {
            if let selectedFile = selectedFile, selectedFile.isMarkdownFile {
                MarkdownDetailView(fileItem: selectedFile)
                    .id(selectedFile.url.absoluteString)
            } else if let openedFile = openedExternalFile {
                MarkdownDetailView(fileItem: openedFile)
                    .id(openedFile.url.absoluteString)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("选择一个Markdown文件来查看内容")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("从系统中打开文件") {
                        openFileFromSystem()
                    }
                    .buttonStyle(.borderedProminent)
                    .help("选择系统中的 Markdown 文件")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func loadFeaturesFile() {
        // 首先尝试加载上次打开的文件
        if let lastFileURL = FileManager.default.getLastOpenedFileURL() {
            let lastFile = FileItem(url: lastFileURL)
            if lastFile.isMarkdownFile {
                // 判断是否为外部文件（不在Documents目录中）
                if !lastFileURL.path.hasPrefix(FileManager.default.documentsDirectory.path) {
                    // 外部文件需要开始访问安全范围资源
                    if lastFileURL.startAccessingSecurityScopedResource() {
                        documentHandler.securityScopedURLs.append(lastFileURL)
                    }
                    openedExternalFile = lastFile
                    selectedFile = nil
                } else {
                    selectedFile = lastFile
                    openedExternalFile = nil
                }
                return
            }
        }
        
        // 如果没有上次打开的文件，则自动加载Features.md文件
        let featuresURL = FileManager.default.documentsDirectory.appendingPathComponent("Features.md")
        if FileManager.default.fileExists(atPath: featuresURL.path) {
            let featuresFile = FileItem(url: featuresURL)
            if featuresFile.isMarkdownFile {
                selectedFile = featuresFile
                FileManager.default.saveLastOpenedFile(featuresURL)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("没有找到文件")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("目录中没有任何文件。尝试添加一些Markdown文件到应用的文档目录。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button("创建示例文件") {
                    createSampleFiles()
                }
                .buttonStyle(.bordered)
                
                Button("从系统中打开") {
                    openFileFromSystem()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 显示外部文件历史记录
            let externalHistory = FileManager.default.getExternalFileHistory()
            if !externalHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近打开的文件")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(Array(externalHistory.prefix(5).enumerated()), id: \.offset) { index, filePath in
                        if FileManager.default.fileExists(atPath: filePath) {
                            Button(action: {
                                openRecentFile(filePath)
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.orange)
                                    Text(URL(fileURLWithPath: filePath).lastPathComponent)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.top)
            }
        }
        .padding()
    }
    
    private var fileListView: some View {
        List(selection: $selectedFile) {
            // 显示当前目录路径
            Section {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(currentDirectory.lastPathComponent)
                        .font(.headline)
                    Spacer()
                    Text("\(fileItems.count) 个项目")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                // 如果有外部打开的文件，显示在这里
                if let openedFile = openedExternalFile {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.orange)
                        Text("外部文件: \(openedFile.name)")
                            .font(.subheadline)
                        Spacer()
                        Button("关闭") {
                            openedExternalFile = nil
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // 文件列表
            Section("文件") {
                ForEach(fileItems) { item in
                    FileItemRow(item: item) {
                        handleFileSelection(item)
                    }
                    .tag(item)
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    private func setupInitialFiles() {
        // 创建示例文件（如果不存在）
        FileManager.default.createSampleMarkdownFiles()
        
        // 清理无效的历史记录
        FileManager.default.cleanupExternalFileHistory()
    }
    
    private func loadFiles() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let urls = FileManager.default.contentsOfDirectory(at: currentDirectory)
            let items = urls.map { FileItem(url: $0) }
            
            DispatchQueue.main.async {
                self.fileItems = items
                self.isLoading = false
            }
        }
    }
    
    private func handleFileSelection(_ item: FileItem) {
        if item.isDirectory {
            // 进入目录
            currentDirectory = item.url
            loadFiles()
        } else if item.isMarkdownFile {
            // 选择Markdown文件
            selectedFile = item
            openedExternalFile = nil // 清除外部文件选择
            
            // 保存到历史记录
            FileManager.default.saveLastOpenedFile(item.url)
        } else {
            // 显示不支持的文件类型提示
            errorMessage = "不支持的文件类型：\(item.url.pathExtension)"
        }
    }
    
    private func createSampleFiles() {
        FileManager.default.createSampleMarkdownFiles()
        loadFiles()
    }
    
    private func openFileFromSystem() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        // 设置支持的文件类型
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md")!,
            UTType(filenameExtension: "markdown")!,
            UTType(filenameExtension: "mdown")!,
            UTType(filenameExtension: "mkdn")!,
            UTType(filenameExtension: "mkd")!
        ]
        
        panel.title = "选择 Markdown 文件"
        panel.message = "请选择一个 Markdown 文件来查看"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    let fileItem = FileItem(url: url)
                    if fileItem.isMarkdownFile {
                        self.openedExternalFile = fileItem
                        self.selectedFile = nil // 清除本地文件选择
                        
                        // 保存到历史记录
                        FileManager.default.saveLastOpenedFile(url)
                        FileManager.default.addToExternalFileHistory(url)
                    } else {
                        self.errorMessage = "选择的文件不是有效的 Markdown 文件"
                    }
                }
            }
        }
    }
    
    private func handleExternalFile(_ url: URL) {
        let fileItem = FileItem(url: url)
        if fileItem.isMarkdownFile {
            openedExternalFile = fileItem
            selectedFile = nil
        } else {
            errorMessage = "选择的文件不是有效的 Markdown 文件"
        }
    }
    
    private func openRecentFile(_ filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileItem = FileItem(url: fileURL)
        
        if fileItem.isMarkdownFile && FileManager.default.fileExists(atPath: filePath) {
            // 对于外部文件，通过DocumentHandler处理安全范围访问
            if !filePath.hasPrefix(FileManager.default.documentsDirectory.path) {
                documentHandler.handleOpenURL(fileURL)
            } else {
                openedExternalFile = fileItem
                selectedFile = nil
                
                // 更新历史记录（移到最前面）
                FileManager.default.saveLastOpenedFile(fileURL)
                FileManager.default.addToExternalFileHistory(fileURL)
            }
        } else {
            errorMessage = "文件不存在或不是有效的 Markdown 文件"
            // 清理无效的历史记录
            FileManager.default.cleanupExternalFileHistory()
        }
    }
}

/// 文件项行视图
struct FileItemRow: View {
    let item: FileItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // 文件图标
                Image(systemName: item.iconName)
                    .foregroundColor(colorFromString(item.iconColor))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 文件名
                    Text(item.name)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 文件信息
                    HStack {
                        if !item.isDirectory {
                            Text(item.formattedSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(item.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 箭头指示器
                if item.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if item.isMarkdownFile {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "blue":
            return .blue
        case "green":
            return .green
        case "gray":
            return .gray
        default:
            return .primary
        }
    }
}

#Preview {
    FileBrowserView()
        .environmentObject(DocumentHandler())
} 