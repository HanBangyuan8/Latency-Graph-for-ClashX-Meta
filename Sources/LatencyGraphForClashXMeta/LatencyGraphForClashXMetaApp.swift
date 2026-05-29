import SwiftUI
import Charts
import Foundation
import AppKit
import SQLite3

struct ProbeRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let timestamp: Date
    let proxyName: String
    let target: String
    let latencyMs: Int?
    let success: Bool
    let errorDescription: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        proxyName: String,
        target: String,
        latencyMs: Int?,
        success: Bool,
        errorDescription: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.proxyName = proxyName
        self.target = target
        self.latencyMs = latencyMs
        self.success = success
        self.errorDescription = errorDescription
    }
}

struct StatsSummary {
    let lastLatency: Int?
    let avgLatency24h: Double?
    let maxLatency24h: Int?
    let availability24h: Double
    let packetLoss24h: Double
    let totalSamples24h: Int
    let failureCount24h: Int
}

struct ProbeBatchResult: Sendable {
    let proxyName: String
    let latencyMs: Int?
    let errorDescription: String?
}

enum ProbeRecordCSVFormatter {
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func csv(records: [ProbeRecord]) -> String {
        let header = ["timestamp", "proxy_name", "target", "latency_ms", "success", "error_description"]
        let rows = records.map { record in
            [
                formatter.string(from: record.timestamp),
                record.proxyName,
                record.target,
                record.latencyMs.map(String.init) ?? "",
                record.success ? "true" : "false",
                record.errorDescription ?? ""
            ]
            .map(escape)
            .joined(separator: ",")
        }
        return ([header.joined(separator: ",")] + rows).joined(separator: "\n") + "\n"
    }

    static func escape(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }
}

enum ByteSizeFormatter {
    static func string(from bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

enum ProbeHistoryManager {
    static func clearing(records: [ProbeRecord], proxyName: String) -> [ProbeRecord] {
        let trimmed = proxyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return records }
        return records.filter { $0.proxyName != trimmed }
    }
}

struct DelaySampleResult: Sendable {
    let latencyMs: Int?
    let errorDescription: String?
}

struct DelayResponse: Decodable {
    let delay: Int
}

struct ProxyGroupResponse: Decodable {
    let proxies: [String: ProxyNode]
}

struct ProxyNode: Decodable {
    let name: String?
    let type: String?
    let now: String?
    let all: [String]?
    let history: [ProxyHistory]?
}

struct ProxyHistory: Decodable {
    let time: String
    let delay: Int
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: "en"
        case .simplifiedChinese: "zh-Hans"
        case .traditionalChinese: "zh-Hant"
        }
    }

}

enum MotionIntensity: String, CaseIterable, Identifiable {
    case enhanced
    case reduced
    case none

    var id: String { rawValue }
}

struct AccentColorOption: Identifiable, Hashable {
    let id: String
    let simplifiedName: String
    let traditionalName: String
    let englishName: String
    let color: Color

    func name(for language: AppLanguage) -> String {
        switch language {
        case .english: englishName
        case .simplifiedChinese: simplifiedName
        case .traditionalChinese: traditionalName
        }
    }

    static let all: [AccentColorOption] = [
        AccentColorOption(id: "red", simplifiedName: "红", traditionalName: "紅", englishName: "Red", color: Color(red: 0.90, green: 0.24, blue: 0.28)),
        AccentColorOption(id: "orange", simplifiedName: "橙", traditionalName: "橙", englishName: "Orange", color: Color(red: 0.94, green: 0.48, blue: 0.16)),
        AccentColorOption(id: "yellow", simplifiedName: "黄", traditionalName: "黃", englishName: "Yellow", color: Color(red: 0.90, green: 0.72, blue: 0.18)),
        AccentColorOption(id: "green", simplifiedName: "绿", traditionalName: "綠", englishName: "Green", color: Color(red: 0.22, green: 0.70, blue: 0.38)),
        AccentColorOption(id: "cyan", simplifiedName: "青", traditionalName: "青", englishName: "Cyan", color: Color(red: 0.10, green: 0.70, blue: 0.76)),
        AccentColorOption(id: "blue", simplifiedName: "蓝", traditionalName: "藍", englishName: "Blue", color: Color(red: 0.20, green: 0.48, blue: 0.92)),
        AccentColorOption(id: "purple", simplifiedName: "紫", traditionalName: "紫", englishName: "Purple", color: Color(red: 0.56, green: 0.34, blue: 0.88)),
        AccentColorOption(id: "pink", simplifiedName: "粉", traditionalName: "粉", englishName: "Pink", color: Color(red: 0.92, green: 0.34, blue: 0.62)),
        AccentColorOption(id: "rose", simplifiedName: "玫瑰", traditionalName: "玫瑰", englishName: "Rose", color: Color(red: 0.86, green: 0.30, blue: 0.42)),
        AccentColorOption(id: "amber", simplifiedName: "琥珀", traditionalName: "琥珀", englishName: "Amber", color: Color(red: 0.96, green: 0.58, blue: 0.18)),
        AccentColorOption(id: "lime", simplifiedName: "青柠", traditionalName: "青檸", englishName: "Lime", color: Color(red: 0.54, green: 0.76, blue: 0.22)),
        AccentColorOption(id: "mint", simplifiedName: "薄荷", traditionalName: "薄荷", englishName: "Mint", color: Color(red: 0.18, green: 0.72, blue: 0.56)),
        AccentColorOption(id: "teal", simplifiedName: "蓝绿", traditionalName: "藍綠", englishName: "Teal", color: Color(red: 0.12, green: 0.58, blue: 0.70)),
        AccentColorOption(id: "indigo", simplifiedName: "靛蓝", traditionalName: "靛藍", englishName: "Indigo", color: Color(red: 0.36, green: 0.38, blue: 0.86)),
        AccentColorOption(id: "darkGray", simplifiedName: "深灰", traditionalName: "深灰", englishName: "Dark Gray", color: Color(red: 0.36, green: 0.38, blue: 0.43)),
        AccentColorOption(id: "lightGray", simplifiedName: "浅灰", traditionalName: "淺灰", englishName: "Light Gray", color: Color(red: 0.72, green: 0.74, blue: 0.78))
    ]

    static func option(for id: String) -> AccentColorOption {
        all.first { $0.id == id } ?? all[6]
    }
}

enum L10n {
    static func text(_ key: String, language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            simplified[key] ?? key
        case .traditionalChinese:
            traditional[key] ?? simplified[key] ?? key
        case .english:
            english[key] ?? key
        }
    }

    private static let simplified: [String: String] = [:]
    private static let traditional: [String: String] = [
        "控制": "控制", "状态": "狀態", "当前节点": "目前節點", "监控节点数": "監控節點數", "监控状态": "監控狀態",
        "运行中": "執行中", "已停止": "已停止", "开始监控": "開始監控", "停止监控": "停止監控", "立即探测": "立即探測",
        "刷新代理列表": "重新整理代理列表", "删除历史数据": "刪除歷史資料", "Overview": "總覽", "节点分页": "節點分頁",
        "节点监控": "節點監控", "上次延迟": "上次延遲", "24h 平均延迟": "24h 平均延遲", "24h 最高延迟": "24h 最高延遲",
        "24h 丢包率": "24h 丟包率", "24h 可用率": "24h 可用率", "延迟曲线": "延遲曲線", "时间范围": "時間範圍",
        "还没有延迟数据": "還沒有延遲資料", "点击“开始监控”或“立即探测”后，这里会开始画曲线。": "點擊「開始監控」或「立即探測」後，這裡會開始畫曲線。",
        "最近记录": "最近記錄", "清空历史": "清空歷史", "时间": "時間", "节点": "節點", "结果": "結果", "成功": "成功",
        "失败": "失敗", "延迟": "延遲", "说明": "說明", "设置": "設定", "从剪贴板读取": "從剪貼簿讀取", "未设置": "未設定",
        "已设置": "已設定", "清空": "清空", "自动监控代理组所有节点": "自動監控代理組所有節點", "跟随代理组当前节点": "跟隨代理組目前節點",
        "代理组": "代理組", "手动多选节点": "手動多選節點", "勾选多个节点后，每轮采样都会分别记录，并在左侧节点分页中逐页查看。": "勾選多個節點後，每輪採樣都會分別記錄，並在左側節點分頁中逐頁查看。",
        "探测目标": "探測目標", "数据点间隔": "資料點間隔", "测速超时": "測速逾時", "每点探测次数": "每點探測次數",
        "次，取最小值": "次，取最小值", "点击“刷新代理列表”后选择节点。": "點擊「重新整理代理列表」後選擇節點。",
        "所有选择节点": "所有選擇節點", "等待数据": "等待資料", "监控中": "監控中", "趋势": "趨勢", "节点概览": "節點總覽",
        "合并延迟曲线": "合併延遲曲線", "主要颜色": "主要顏色", "个手动节点": "個手動節點", "刷新代理目录失败": "重新整理代理目錄失敗",
        "已取消": "已取消", "检查更新": "檢查更新", "发现新版本 %@": "發現新版本 %@", "已经是最新版本": "已經是最新版本",
        "检查更新失败": "檢查更新失敗", "打开下载页": "打開下載頁", "每日自动检查": "每日自動檢查",
        "Language": "語言", "动态效果": "動態效果", "增强": "增強", "减弱": "減弱", "无动画": "無動畫", "Controller URL": "控制器 URL", "Secret": "密鑰",
        "连接与认证": "連線與認證", "监控节点": "監控節點", "探测参数": "探測參數",
        "测速中": "測速中", "已暂停：未测到": "已暫停：未測到", "天": "天", "已清空全部历史": "已清空全部歷史",
        "没有可清理的历史": "沒有可清理的歷史", "历史已清理": "歷史已清理", "导出 CSV": "匯出 CSV",
        "已导出": "已匯出", "导出失败": "匯出失敗", "数据库管理": "資料庫管理", "数据库大小": "資料庫大小",
        "数据库": "資料庫", "记录数": "記錄數", "保留策略": "保留策略", "历史管理": "歷史管理", "清理此节点": "清理此節點"
    ]
    private static let english: [String: String] = [
        "控制": "Control", "状态": "Status", "当前节点": "Current Node", "监控节点数": "Monitored Nodes", "监控状态": "Monitoring",
        "运行中": "Running", "已停止": "Stopped", "开始监控": "Start Monitoring", "停止监控": "Stop Monitoring", "立即探测": "Probe Now",
        "刷新代理列表": "Refresh Proxies", "删除历史数据": "Delete History", "Overview": "Overview", "节点分页": "Node Pages",
        "节点监控": "Node Monitor", "上次延迟": "Last Latency", "24h 平均延迟": "24h Avg Latency", "24h 最高延迟": "24h Max Latency",
        "24h 丢包率": "24h Packet Loss", "24h 可用率": "24h Availability", "延迟曲线": "Latency Chart", "时间范围": "Time Range",
        "还没有延迟数据": "No latency data yet", "点击“开始监控”或“立即探测”后，这里会开始画曲线。": "Click Start Monitoring or Probe Now to start drawing the chart.",
        "最近记录": "Recent Records", "清空历史": "Clear History", "时间": "Time", "节点": "Node", "结果": "Result", "成功": "Success",
        "失败": "Failed", "延迟": "Latency", "说明": "Notes", "设置": "Settings", "从剪贴板读取": "Paste", "未设置": "Not set",
        "已设置": "Set", "清空": "Clear", "自动监控代理组所有节点": "Monitor all nodes in group", "跟随代理组当前节点": "Follow selected group node",
        "代理组": "Proxy Group", "手动多选节点": "Manual Multi-select Nodes", "勾选多个节点后，每轮采样都会分别记录，并在左侧节点分页中逐页查看。": "Selected nodes are recorded separately each batch and shown as pages in the sidebar.",
        "探测目标": "Probe Target", "数据点间隔": "Data Point Interval", "测速超时": "Delay Timeout", "每点探测次数": "Samples per Point",
        "次，取最小值": "samples, minimum", "点击“刷新代理列表”后选择节点。": "Refresh proxies, then choose nodes.",
        "所有选择节点": "All Selected Nodes", "等待数据": "Waiting for data", "监控中": "Monitoring", "趋势": "Trend", "节点概览": "Node Overview",
        "合并延迟曲线": "Combined Latency Chart", "主要颜色": "Accent Color", "个手动节点": "manual nodes", "刷新代理目录失败": "Failed to refresh proxy catalog",
        "已取消": "Cancelled", "检查更新": "Check for Updates", "发现新版本 %@": "New version available: %@", "已经是最新版本": "Already up to date",
        "检查更新失败": "Update check failed", "打开下载页": "Open Download Page", "每日自动检查": "Daily automatic check",
        "Language": "Language", "动态效果": "Motion", "增强": "Enhanced", "减弱": "Reduced", "无动画": "Off", "Controller URL": "Controller URL", "Secret": "Secret",
        "连接与认证": "Connection & Auth", "监控节点": "Monitored Nodes", "探测参数": "Probe Settings",
        "测速中": "Testing", "已暂停：未测到": "Paused: no probes", "天": "days", "已清空全部历史": "All history cleared",
        "没有可清理的历史": "No history to clear", "历史已清理": "History cleared", "导出 CSV": "Export CSV",
        "已导出": "Exported", "导出失败": "Export failed", "数据库管理": "Database", "数据库大小": "Database Size",
        "数据库": "Database", "记录数": "Records", "保留策略": "Retention", "历史管理": "History", "清理此节点": "Clear Node"
    ]
}

@MainActor
final class AppModel: ObservableObject {
    @Published var controllerURL: String { didSet { UserDefaults.standard.set(controllerURL, forKey: "controllerURL") } }
    @Published var controllerSecret: String { didSet { UserDefaults.standard.set(controllerSecret, forKey: "controllerSecret") } }
    @Published var proxyName: String { didSet { UserDefaults.standard.set(proxyName, forKey: "proxyName") } }
    @Published var manualProxyNames: String { didSet { UserDefaults.standard.set(manualProxyNames, forKey: "manualProxyNames") } }
    @Published var targetURL: String { didSet { UserDefaults.standard.set(targetURL, forKey: "targetURL") } }
    @Published var probeIntervalMs: Int { didSet { UserDefaults.standard.set(probeIntervalMs, forKey: "probeIntervalMs") } }
    @Published var delayTimeoutMs: Int { didSet { UserDefaults.standard.set(delayTimeoutMs, forKey: "delayTimeoutMs") } }
    @Published var probeSampleCount: Int { didSet { UserDefaults.standard.set(probeSampleCount, forKey: "probeSampleCount") } }
    @Published var useSelectedProxyFromGroup: Bool { didSet { UserDefaults.standard.set(useSelectedProxyFromGroup, forKey: "useSelectedProxyFromGroup") } }
    @Published var monitorAllProxiesInGroup: Bool { didSet { UserDefaults.standard.set(monitorAllProxiesInGroup, forKey: "monitorAllProxiesInGroup") } }
    @Published var proxyGroupName: String { didSet { UserDefaults.standard.set(proxyGroupName, forKey: "proxyGroupName") } }
    @Published var languageCode: String { didSet { UserDefaults.standard.set(languageCode, forKey: "languageCode") } }
    @Published var accentColorID: String { didSet { UserDefaults.standard.set(accentColorID, forKey: "accentColorID") } }
    @Published var motionIntensityID: String { didSet { UserDefaults.standard.set(motionIntensityID, forKey: "motionIntensityID") } }
    @Published var lastUpdateCheckAt: Double { didSet { UserDefaults.standard.set(lastUpdateCheckAt, forKey: "lastUpdateCheckAt") } }

    @Published private(set) var recordsRevision = 0
    @Published var isRunning = false
    @Published var latestError: String?
    @Published var updateStatus: String?
    @Published var updateURL: URL?
    @Published var isCheckingForUpdates = false
    @Published var availableProxyGroups: [String] = []
    @Published var availableProxies: [String] = []
    @Published var resolvedProxyName: String = "DIRECT"
    @Published var monitoredProxyNames: [String] = ["DIRECT"]
    @Published var isTesting = false
    @Published private(set) var lastProbeStartedAt: Date?
    @Published private(set) var lastProbeCompletedAt: Date?
    @Published private(set) var lastProbeAttemptCount = 0
    @Published private(set) var lastProbeSuccessCount = 0
    @Published var databaseStatusMessage: String?

    private var monitoringTask: Task<Void, Never>?
    private let store = ProbeStore()
    private let persistenceWorker = ProbePersistenceWorker()
    private let client = ClashAPIClient()
    private let updateService = GitHubReleaseUpdateService(owner: "HanBangyuan8", repo: "Latency-Graph-for-ClashX-Meta")
    private let manualProxySeparator = "\n"
    private(set) var records: [ProbeRecord] = []
    private var recordIndex = ProbeRecordIndex(records: [])
    private var statsCache: [ProbeStatsCacheKey: StatsSummary] = [:]
    private var chartCache: [ProbeChartCacheKey: [ProbeRecord]] = [:]
    let runtimePlan = RuntimeFeaturePlan.current

    var runtimeProfile: RuntimeOptimizationProfile {
        runtimePlan.profile
    }

    var selectedManualProxyNames: [String] {
        manualProxyNames
            .components(separatedBy: manualProxySeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .simplifiedChinese
    }

    var accentColor: Color {
        AccentColorOption.option(for: accentColorID).color
    }

    var motionIntensity: MotionIntensity {
        MotionIntensity(rawValue: motionIntensityID) ?? .enhanced
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    var monitoringStatusText: String {
        if isTesting {
            return t("测速中")
        }
        if isRunning {
            if lastProbeAttemptCount == 0, latestError?.isEmpty == false {
                return t("已暂停：未测到")
            }
            if lastProbeAttemptCount > 0 {
                return "\(t("运行中")) \(lastProbeSuccessCount)/\(lastProbeAttemptCount)"
            }
            return t("运行中")
        }
        return t("已停止")
    }

    var databaseSizeText: String {
        ByteSizeFormatter.string(from: store.databaseSizeBytes())
    }

    var retentionPolicyText: String {
        "\(runtimePlan.retentionDays) \(t("天"))"
    }

    var databaseRecordCountText: String {
        "\(records.count)"
    }

    func t(_ key: String) -> String {
        L10n.text(key, language: language)
    }

    func displayError(_ description: String) -> String {
        description
            .replacingOccurrences(of: "已取消", with: t("已取消"))
            .replacingOccurrences(of: "cancelled", with: t("已取消"), options: [.caseInsensitive])
            .replacingOccurrences(of: "canceled", with: t("已取消"), options: [.caseInsensitive])
    }

    init() {
        let defaults = UserDefaults.standard
        self.controllerURL = defaults.string(forKey: "controllerURL") ?? "http://127.0.0.1:9090"
        self.controllerSecret = defaults.string(forKey: "controllerSecret") ?? ""
        self.proxyName = defaults.string(forKey: "proxyName") ?? "DIRECT"
        self.manualProxyNames = defaults.string(forKey: "manualProxyNames") ?? "DIRECT"
        self.targetURL = defaults.string(forKey: "targetURL") ?? "https://www.gstatic.com/generate_204"
        self.probeIntervalMs = defaults.object(forKey: "probeIntervalMs") as? Int ?? 30000
        self.delayTimeoutMs = defaults.object(forKey: "delayTimeoutMs") as? Int ?? 5000
        self.probeSampleCount = defaults.object(forKey: "probeSampleCount") as? Int ?? 3
        self.useSelectedProxyFromGroup = defaults.object(forKey: "useSelectedProxyFromGroup") as? Bool ?? false
        self.monitorAllProxiesInGroup = defaults.object(forKey: "monitorAllProxiesInGroup") as? Bool ?? false
        self.proxyGroupName = defaults.string(forKey: "proxyGroupName") ?? "GLOBAL"
        self.languageCode = defaults.string(forKey: "languageCode") ?? AppLanguage.simplifiedChinese.rawValue
        self.accentColorID = defaults.string(forKey: "accentColorID") ?? "purple"
        self.motionIntensityID = defaults.string(forKey: "motionIntensityID") ?? MotionIntensity.enhanced.rawValue
        self.lastUpdateCheckAt = defaults.object(forKey: "lastUpdateCheckAt") as? Double ?? 0
        normalizeStoredChoices()
        let loadedRecords = store.loadRecords()
        self.records = loadedRecords
        self.recordIndex = ProbeRecordIndex(records: loadedRecords)
        self.resolvedProxyName = proxyName
        self.monitoredProxyNames = selectedManualProxyNames.isEmpty ? [proxyName] : selectedManualProxyNames
        Task {
            await refreshProxyCatalog()
            await checkForUpdatesIfNeeded()
        }
    }

    deinit {
        monitoringTask?.cancel()
    }

    func startMonitoring() {
        guard !isRunning else { return }
        isRunning = true
        latestError = nil
        scheduleMonitoringLoop()
    }

    func stopMonitoring() {
        isRunning = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    func rescheduleMonitoringIfNeeded() {
        guard isRunning else { return }
        scheduleMonitoringLoop()
    }

    private func normalizeStoredChoices() {
        let allowedIntervals = [5000, 10000, 30000, 60000, 120000]
        if !allowedIntervals.contains(probeIntervalMs) {
            probeIntervalMs = allowedIntervals.min(by: { abs($0 - probeIntervalMs) < abs($1 - probeIntervalMs) }) ?? 5000
        }
        probeSampleCount = min(5, max(1, probeSampleCount))
    }

    func clearHistory() {
        records.removeAll()
        recordIndex.replace(with: records)
        invalidateRecordDerivedState()
        persistRecords(immediate: true)
        databaseStatusMessage = t("已清空全部历史")
    }

    func clearHistory(for proxyName: String) {
        let trimmed = proxyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let originalCount = records.count
        let nextRecords = ProbeHistoryManager.clearing(records: records, proxyName: trimmed)
        guard nextRecords.count != originalCount else {
            databaseStatusMessage = "\(trimmed): \(t("没有可清理的历史"))"
            return
        }
        records = nextRecords
        recordIndex.replace(with: records)
        invalidateRecordDerivedState()
        persistRecords(immediate: true)
        databaseStatusMessage = "\(trimmed): \(t("历史已清理"))"
    }

    func exportHistoryCSV() {
        let panel = NSSavePanel()
        panel.title = t("导出 CSV")
        panel.nameFieldStringValue = "latency-history-\(Self.exportTimestamp()).csv"
        panel.allowedFileTypes = ["csv"]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ProbeRecordCSVFormatter.csv(records: records).write(to: url, atomically: true, encoding: .utf8)
            databaseStatusMessage = "\(t("已导出")) \(url.lastPathComponent)"
        } catch {
            databaseStatusMessage = "\(t("导出失败"))：\(error.localizedDescription)"
        }
    }

    func setManualProxy(_ proxy: String, isSelected: Bool) {
        var selected = selectedManualProxyNames
        if isSelected {
            if !selected.contains(proxy) {
                selected.append(proxy)
            }
        } else {
            selected.removeAll { $0 == proxy }
        }
        manualProxyNames = selected.joined(separator: manualProxySeparator)
        if !useSelectedProxyFromGroup && !monitorAllProxiesInGroup {
            monitoredProxyNames = selected.isEmpty ? ["DIRECT"] : selected
            resolvedProxyName = monitoredProxyNames.count == 1 ? monitoredProxyNames[0] : "\(monitoredProxyNames.count) \(t("个手动节点"))"
        }
    }

    func refreshProxyCatalog() async {
        do {
            let data = try await client.fetchProxies(baseURLString: controllerURL, secret: controllerSecret)
            let response = try JSONDecoder().decode(ProxyGroupResponse.self, from: data)
            let entries = response.proxies

            let groups = entries.compactMap { key, value -> String? in
                guard value.type?.lowercased().contains("selector") == true || value.type?.lowercased().contains("urltest") == true || value.type?.lowercased().contains("fallback") == true else {
                    return nil
                }
                return key
            }.sorted()

            let proxies = entries.compactMap { key, value -> String? in
                if value.all?.isEmpty == false {
                    return nil
                }
                return key
            }.sorted()
            availableProxyGroups = groups
            availableProxies = proxies

            if monitorAllProxiesInGroup {
                monitoredProxyNames = try resolveAllProxyNames(in: response)
                resolvedProxyName = "\(proxyGroupName) · \(monitoredProxyNames.count) \(t("节点"))"
            } else if useSelectedProxyFromGroup {
                resolvedProxyName = try resolveProxyName(from: response)
                monitoredProxyNames = [resolvedProxyName]
            } else {
                let manualProxies = selectedManualProxyNames
                monitoredProxyNames = manualProxies.isEmpty ? [proxyName] : manualProxies
                resolvedProxyName = monitoredProxyNames.count == 1 ? monitoredProxyNames[0] : "\(monitoredProxyNames.count) \(t("个手动节点"))"
            }
        } catch {
            latestError = "\(t("刷新代理目录失败"))：\(error.localizedDescription)"
        }
    }

    func runProbe() async {
        guard !isTesting else { return }
        isTesting = true
        defer { isTesting = false }
        let batchStartedAt = Date()
        let wasMonitoring = isRunning
        lastProbeStartedAt = batchStartedAt

        do {
            let data = try await client.fetchProxies(baseURLString: controllerURL, secret: controllerSecret)
            let response = try JSONDecoder().decode(ProxyGroupResponse.self, from: data)
            let proxyNames = try validateProbeTargets(try resolveMonitoredProxyNames(from: response), in: response)

            monitoredProxyNames = proxyNames
            if monitorAllProxiesInGroup {
                resolvedProxyName = "\(proxyGroupName) · \(proxyNames.count) \(t("节点"))"
            } else if useSelectedProxyFromGroup {
                resolvedProxyName = proxyNames.first ?? proxyName
            } else {
                resolvedProxyName = proxyNames.count == 1 ? proxyNames[0] : "\(proxyNames.count) \(t("个手动节点"))"
            }

            let batchResults = await runProbeBatch(proxyNames: proxyNames)
            lastProbeAttemptCount = batchResults.count
            lastProbeSuccessCount = batchResults.filter { $0.latencyMs != nil }.count
            lastProbeCompletedAt = Date()
            let errors = batchResults.compactMap { result -> String? in
                guard let errorDescription = result.errorDescription else {
                    return nil
                }
                return "\(result.proxyName): \(errorDescription)"
            }

            append(batchResults.map { result in
                ProbeRecord(
                    timestamp: batchStartedAt,
                    proxyName: result.proxyName,
                    target: targetURL,
                    latencyMs: result.latencyMs,
                    success: result.latencyMs != nil,
                    errorDescription: result.errorDescription
                )
            })

            latestError = errors.isEmpty ? nil : errors.joined(separator: "\n")
        } catch {
            let failedProxy = resolvedProxyName.isEmpty ? proxyName : resolvedProxyName
            lastProbeAttemptCount = 0
            lastProbeSuccessCount = 0
            lastProbeCompletedAt = Date()
            let record = ProbeRecord(
                timestamp: batchStartedAt,
                proxyName: failedProxy,
                target: targetURL,
                latencyMs: nil,
                success: false,
                errorDescription: error.localizedDescription
            )
            append([record])
            latestError = error.localizedDescription
            if wasMonitoring {
                stopMonitoringAfterProbeSetupFailure()
            }
        }
    }

    func stats(for proxy: String? = nil) -> StatsSummary {
        stats(for: proxy.map { [$0] })
    }

    func stats(for proxies: [String]?) -> StatsSummary {
        let key = ProbeStatsCacheKey(
            proxies: normalizedProxyKey(proxies),
            minuteBucket: currentMinuteBucket()
        )
        if let cached = statsCache[key] {
            return cached
        }

        let summary = recordIndex.stats(for: proxies)
        statsCache[key] = summary
        return summary
    }

    func chartData(
        hours: Double = 24,
        proxy: String? = nil,
        maxTotalPoints: Int? = nil,
        minimumPointsPerSeries: Int = 220
    ) -> [ProbeRecord] {
        chartData(
            hours: hours,
            proxies: proxy.map { [$0] },
            maxTotalPoints: maxTotalPoints,
            minimumPointsPerSeries: minimumPointsPerSeries
        )
    }

    func chartData(
        hours: Double = 24,
        proxies: [String]?,
        maxTotalPoints: Int? = nil,
        minimumPointsPerSeries: Int = 220
    ) -> [ProbeRecord] {
        let maxPoints = maxTotalPoints ?? defaultChartPointBudget(hours: hours)
        let key = ProbeChartCacheKey(
            hours: hours,
            proxies: normalizedProxyKey(proxies),
            maxTotalPoints: maxPoints,
            minimumPointsPerSeries: minimumPointsPerSeries,
            minuteBucket: currentMinuteBucket()
        )
        if let cached = chartCache[key] {
            return cached
        }

        let data = recordIndex.chartData(
            hours: hours,
            proxies: proxies,
            maxTotalPoints: maxPoints,
            minimumPointsPerSeries: minimumPointsPerSeries
        )
        chartCache[key] = data
        return data
    }

    func recentRecords(for proxy: String? = nil, limit: Int) -> [ProbeRecord] {
        recordIndex.recentRecords(for: proxy, limit: limit)
    }

    func nodeChartPointBudget(hours: Double) -> Int {
        if hours <= 4 { return runtimeProfile.nodeChartBudgetSmallRange }
        if hours <= 24 { return runtimeProfile.nodeChartBudgetDayRange }
        if hours <= 168 { return runtimeProfile.nodeChartBudgetWeekRange }
        return runtimeProfile.nodeChartBudgetLongRange
    }

    func overviewChartPointBudget(hours: Double, seriesCount: Int) -> Int {
        let basePerSeries: Int
        if hours <= 4 {
            basePerSeries = runtimeProfile.overviewBasePointsSmallRange
        } else if hours <= 24 {
            basePerSeries = runtimeProfile.overviewBasePointsDayRange
        } else if hours <= 168 {
            basePerSeries = runtimeProfile.overviewBasePointsWeekRange
        } else {
            basePerSeries = runtimeProfile.overviewBasePointsLongRange
        }
        return min(runtimeProfile.overviewTotalPointCeiling, max(basePerSeries, basePerSeries * max(seriesCount, 1)))
    }

    private func defaultChartPointBudget(hours: Double) -> Int {
        if hours <= 4 { return 1_000 }
        if hours <= 24 { return 1_200 }
        if hours <= 168 { return 1_400 }
        return 1_600
    }

    func checkForUpdatesIfNeeded() async {
        let now = Date().timeIntervalSince1970
        guard now - lastUpdateCheckAt >= 24 * 60 * 60 else { return }
        await checkForUpdates(isAutomatic: true)
    }

    func checkForUpdates(isAutomatic: Bool = false) async {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        defer { isCheckingForUpdates = false }

        do {
            let release = try await updateService.latestRelease()
            lastUpdateCheckAt = Date().timeIntervalSince1970
            if release.isNewer(than: currentAppVersion) {
                updateURL = release.htmlURL
                updateStatus = String(format: t("发现新版本 %@"), release.displayVersion)
            } else if !isAutomatic {
                updateURL = nil
                updateStatus = t("已经是最新版本")
            }
        } catch {
            if !isAutomatic {
                updateURL = nil
                updateStatus = "\(t("检查更新失败"))：\(error.localizedDescription)"
            }
        }
    }

    func openUpdatePage() {
        guard let updateURL else { return }
        NSWorkspace.shared.open(updateURL)
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.1"
    }

    private func scheduleMonitoringLoop() {
        monitoringTask?.cancel()
        monitoringTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while self.isRunning && !Task.isCancelled {
                let startedAt = Date()
                await self.runProbe()
                guard self.isRunning && !Task.isCancelled else { break }

                let interval = max(0.001, TimeInterval(self.probeIntervalMs) / 1000.0)
                let elapsed = Date().timeIntervalSince(startedAt)
                let sleepSeconds = max(0, interval - elapsed)

                if sleepSeconds > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(sleepSeconds * 1_000_000_000))
                }
            }
        }
    }

    private func runProbeBatch(proxyNames: [String]) async -> [ProbeBatchResult] {
        let configuration = ProbeBatchConfiguration(
            sampleCount: max(1, probeSampleCount),
            sampleConcurrencyLimit: runtimePlan.sampleConcurrencyLimit,
            baseURLString: controllerURL,
            secret: controllerSecret,
            target: targetURL,
            timeoutMs: max(1000, delayTimeoutMs)
        )
        return await ProbeBatchExecutor(
            client: client,
            proxyConcurrencyLimit: runtimePlan.probeConcurrencyLimit
        )
        .run(proxyNames: proxyNames, configuration: configuration)
    }

    private func append(_ newRecords: [ProbeRecord]) {
        guard !newRecords.isEmpty else { return }
        records = recordIndex.appending(
            newRecords,
            to: records,
            retentionDays: runtimePlan.retentionDays
        )
        invalidateRecordDerivedState()
        persistNewRecords(newRecords)
    }

    private func invalidateRecordDerivedState() {
        statsCache.removeAll(keepingCapacity: true)
        chartCache.removeAll(keepingCapacity: true)
        recordsRevision += 1
    }

    private func persistNewRecords(_ newRecords: [ProbeRecord]) {
        let retentionDays = runtimePlan.retentionDays
        Task {
            await persistenceWorker.append(records: newRecords, retentionDays: retentionDays)
        }
    }

    private func normalizedProxyKey(_ proxies: [String]?) -> [String]? {
        guard let proxies, !proxies.isEmpty else { return nil }
        return Array(Set(proxies)).sorted()
    }

    private func currentMinuteBucket() -> Int {
        Int(Date().timeIntervalSince1970 / 60)
    }

    private func persistRecords(immediate: Bool = false) {
        let snapshot = records
        let debounceNanoseconds = runtimePlan.persistenceDebounceNanoseconds
        Task {
            if immediate {
                await persistenceWorker.save(records: snapshot)
            } else {
                await persistenceWorker.scheduleSave(records: snapshot, debounceNanoseconds: debounceNanoseconds)
            }
        }
    }

    private func stopMonitoringAfterProbeSetupFailure() {
        isRunning = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    private func resolveProxyName(from response: ProxyGroupResponse) throws -> String {
        let group = proxyGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let node = response.proxies[group] else {
            throw AppError.custom("代理组不存在：\(group)。请刷新代理列表或检查 Clash 配置。")
        }
        guard let now = node.now, !now.isEmpty else {
            throw AppError.custom("代理组 \(group) 当前未选中任何节点。")
        }
        return now
    }

    private func resolveAllProxyNames(in response: ProxyGroupResponse) throws -> [String] {
        let group = proxyGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let node = response.proxies[group] else {
            throw AppError.custom("代理组不存在：\(group)。请刷新代理列表或检查 Clash 配置。")
        }
        guard let all = node.all, !all.isEmpty else {
            throw AppError.custom("代理组 \(group) 没有可监控的节点列表。")
        }
        return all
    }

    private func resolveMonitoredProxyNames(from response: ProxyGroupResponse) throws -> [String] {
        if monitorAllProxiesInGroup {
            return try resolveAllProxyNames(in: response)
        }
        if useSelectedProxyFromGroup {
            return try [resolveProxyName(from: response)]
        }

        let manualProxies = selectedManualProxyNames
        if !manualProxies.isEmpty {
            return manualProxies
        }

        let legacyManualProxy = proxyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return [legacyManualProxy.isEmpty ? "DIRECT" : legacyManualProxy]
    }

    private func validateProbeTargets(_ proxyNames: [String], in response: ProxyGroupResponse) throws -> [String] {
        let names = proxyNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else {
            throw AppError.custom("没有可测速的节点。请刷新代理列表后重新选择。")
        }

        let missing = names.filter { response.proxies[$0] == nil }
        guard missing.isEmpty else {
            throw AppError.custom("节点已不存在：\(missing.joined(separator: ", "))。已停止监控，请刷新代理列表后重新选择。")
        }
        return names
    }

    private static func exportTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

enum AppError: LocalizedError {
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .custom(let message):
            return message
        }
    }
}

struct ClashAPIClient {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.httpMaximumConnectionsPerHost = 6
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 18
        return URLSession(configuration: configuration)
    }()

    func fetchProxies(baseURLString: String, secret: String) async throws -> Data {
        let request = try makeRequest(baseURLString: baseURLString, path: "/proxies", secret: secret)
        let (data, response) = try await perform(request)
        try validate(response)
        return data
    }

    func testDelay(baseURLString: String, secret: String, proxyName: String, target: String, timeoutMs: Int) async throws -> Int {
        guard var components = URLComponents(string: normalizedBaseURL(baseURLString)) else {
            throw AppError.custom("Controller URL 无效")
        }

        let encodedProxy = proxyName.addingPercentEncoding(withAllowedCharacters: .proxyPathComponentAllowed) ?? proxyName
        components.path = "/proxies/\(encodedProxy)/delay"
        components.queryItems = [
            URLQueryItem(name: "url", value: target),
            URLQueryItem(name: "timeout", value: "\(timeoutMs)")
        ]

        guard let url = components.url else {
            throw AppError.custom("延迟测试 URL 生成失败")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = max(5, Double(timeoutMs) / 1000.0 + 2)
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSecret.isEmpty {
            request.setValue("Bearer \(trimmedSecret)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await perform(request)
        try validate(response)
        let decoded = try JSONDecoder().decode(DelayResponse.self, from: data)
        return decoded.delay
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await Self.session.data(for: request)
        } catch let error as URLError {
            throw AppError.custom(describe(error))
        } catch {
            throw error
        }
    }

    private func makeRequest(baseURLString: String, path: String, secret: String) throws -> URLRequest {
        guard let url = URL(string: normalizedBaseURL(baseURLString) + path) else {
            throw AppError.custom("Controller URL 无效")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSecret.isEmpty {
            request.setValue("Bearer \(trimmedSecret)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.custom("无效响应")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw AppError.custom(describeHTTPStatus(http.statusCode))
        }
    }

    private func describeHTTPStatus(_ statusCode: Int) -> String {
        switch statusCode {
        case 401, 403:
            return "Clash API 认证失败（HTTP \(statusCode)）。请检查 Secret。"
        case 404:
            return "Clash API 路径不存在（HTTP 404）。请检查 Controller URL 或 Clash 版本。"
        case 408:
            return "Clash API 请求超时（HTTP 408）。Clash 控制端没有及时响应。"
        case 429:
            return "Clash API 请求过多（HTTP 429）。请调大数据点间隔或降低节点数量。"
        case 500 ... 599:
            if statusCode == 504 {
                return "Clash API 网关超时（HTTP 504）。本轮没有完成测速，已避免继续显示为正常运行。"
            }
            return "Clash API 服务端错误（HTTP \(statusCode)）。请检查 Clash 是否正常运行。"
        default:
            return "Clash API 返回 HTTP \(statusCode)。"
        }
    }

    private func describe(_ error: URLError) -> String {
        switch error.code {
        case .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
            return "无法连接 Clash API：\(error.localizedDescription)"
        case .timedOut:
            return "Clash API 请求超时：\(error.localizedDescription)"
        case .badURL, .unsupportedURL:
            return "Controller URL 无效：\(error.localizedDescription)"
        default:
            return "Clash API 请求失败：\(error.localizedDescription)"
        }
    }

    private func normalizedBaseURL(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") {
            return String(trimmed.dropLast())
        }
        return trimmed
    }
}

private extension CharacterSet {
    static let proxyPathComponentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#[]@!$&'()*+,;=%")
        return allowed
    }()
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { startIndex in
            Array(self[startIndex ..< Swift.min(startIndex + size, count)])
        }
    }
}

private extension View {
    @ViewBuilder
    func compatibleTint(_ color: Color) -> some View {
        if #available(macOS 13.0, *) {
            tint(color)
        } else {
            accentColor(color)
        }
    }

    @ViewBuilder
    func hideAutomaticWindowToolbar() -> some View {
        if #available(macOS 13.0, *) {
            toolbar(.hidden, for: .windowToolbar)
        } else {
            self
        }
    }

    @ViewBuilder
    func integratedWindowTitlebar(_ enabled: Bool) -> some View {
        if enabled, #available(macOS 11.0, *) {
            ignoresSafeArea(.container, edges: .top)
        } else {
            self
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct ProbeStore {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func loadRecords() -> [ProbeRecord] {
        do {
            let db = try openDatabase()
            defer { sqlite3_close(db) }
            try createSchema(in: db)
            try migrateLegacyJSONIfNeeded(into: db)
            return try fetchRecords(from: db)
        } catch {
            print("load error: \(error)")
            return []
        }
    }

    func save(records: [ProbeRecord]) {
        do {
            let db = try openDatabase()
            defer { sqlite3_close(db) }
            try createSchema(in: db)
            try replaceRecords(records, in: db)
        } catch {
            print("save error: \(error)")
        }
    }

    func append(records: [ProbeRecord], retentionDays: Int) {
        guard !records.isEmpty else { return }
        do {
            let db = try openDatabase()
            defer { sqlite3_close(db) }
            try createSchema(in: db)
            try appendRecords(records, retentionDays: retentionDays, in: db)
        } catch {
            print("append error: \(error)")
        }
    }

    func databaseSizeBytes() -> Int64 {
        do {
            let url = try databaseURL()
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return (attributes[.size] as? NSNumber)?.int64Value ?? 0
        } catch {
            return 0
        }
    }

    private func openDatabase() throws -> OpaquePointer? {
        let url = try databaseURL()
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown SQLite error"
            sqlite3_close(db)
            throw AppError.custom("SQLite open failed: \(message)")
        }
        return db
    }

    private func createSchema(in db: OpaquePointer?) throws {
        try execute(
            """
            CREATE TABLE IF NOT EXISTS probe_records (
                id TEXT PRIMARY KEY NOT NULL,
                timestamp REAL NOT NULL,
                proxy_name TEXT NOT NULL,
                target TEXT NOT NULL,
                latency_ms INTEGER,
                success INTEGER NOT NULL,
                error_description TEXT
            );
            """,
            in: db
        )
        try execute(
            "CREATE INDEX IF NOT EXISTS idx_probe_records_timestamp ON probe_records(timestamp);",
            in: db
        )
        try execute(
            "CREATE INDEX IF NOT EXISTS idx_probe_records_proxy_timestamp ON probe_records(proxy_name, timestamp);",
            in: db
        )
    }

    private func fetchRecords(from db: OpaquePointer?) throws -> [ProbeRecord] {
        let sql = """
        SELECT id, timestamp, proxy_name, target, latency_ms, success, error_description
        FROM probe_records
        ORDER BY timestamp ASC;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw sqliteError(db)
        }
        defer { sqlite3_finalize(statement) }

        var records: [ProbeRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? UUID().uuidString
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let proxyName = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? "DIRECT"
            let target = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
            let latencyMs = sqlite3_column_type(statement, 4) == SQLITE_NULL ? nil : Int(sqlite3_column_int(statement, 4))
            let success = sqlite3_column_int(statement, 5) == 1
            let errorDescription = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            records.append(
                ProbeRecord(
                    id: UUID(uuidString: id) ?? UUID(),
                    timestamp: timestamp,
                    proxyName: proxyName,
                    target: target,
                    latencyMs: latencyMs,
                    success: success,
                    errorDescription: errorDescription
                )
            )
        }
        return records
    }

    private func replaceRecords(_ records: [ProbeRecord], in db: OpaquePointer?) throws {
        try execute("BEGIN TRANSACTION;", in: db)
        do {
            try execute("DELETE FROM probe_records;", in: db)
            for record in records {
                try insert(record, into: db)
            }
            try execute("COMMIT;", in: db)
        } catch {
            try? execute("ROLLBACK;", in: db)
            throw error
        }
    }

    private func appendRecords(_ records: [ProbeRecord], retentionDays: Int, in db: OpaquePointer?) throws {
        let cutoff = Date().addingTimeInterval(-TimeInterval(retentionDays) * 24 * 60 * 60).timeIntervalSince1970
        try execute("BEGIN TRANSACTION;", in: db)
        do {
            for record in records {
                try insert(record, into: db)
            }
            try deleteRecords(before: cutoff, in: db)
            try execute("COMMIT;", in: db)
        } catch {
            try? execute("ROLLBACK;", in: db)
            throw error
        }
    }

    private func deleteRecords(before cutoff: TimeInterval, in db: OpaquePointer?) throws {
        let sql = "DELETE FROM probe_records WHERE timestamp < ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw sqliteError(db)
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_double(statement, 1, cutoff)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError(db)
        }
    }

    private func insert(_ record: ProbeRecord, into db: OpaquePointer?) throws {
        let sql = """
        INSERT OR REPLACE INTO probe_records
        (id, timestamp, proxy_name, target, latency_ms, success, error_description)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw sqliteError(db)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, record.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 2, record.timestamp.timeIntervalSince1970)
        sqlite3_bind_text(statement, 3, record.proxyName, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, record.target, -1, SQLITE_TRANSIENT)
        if let latencyMs = record.latencyMs {
            sqlite3_bind_int(statement, 5, Int32(latencyMs))
        } else {
            sqlite3_bind_null(statement, 5)
        }
        sqlite3_bind_int(statement, 6, record.success ? 1 : 0)
        if let errorDescription = record.errorDescription {
            sqlite3_bind_text(statement, 7, errorDescription, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 7)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError(db)
        }
    }

    private func migrateLegacyJSONIfNeeded(into db: OpaquePointer?) throws {
        let migratedFlag = try appSupportDirectory().appendingPathComponent(".json-migrated-to-sqlite")
        guard !FileManager.default.fileExists(atPath: migratedFlag.path) else { return }
        let legacyURL = try legacyJSONURL()
        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            FileManager.default.createFile(atPath: migratedFlag.path, contents: nil)
            return
        }

        let existing = try fetchRecords(from: db)
        guard existing.isEmpty else {
            FileManager.default.createFile(atPath: migratedFlag.path, contents: nil)
            return
        }

        let data = try Data(contentsOf: legacyURL)
        let records = try decoder.decode([ProbeRecord].self, from: data)
        try replaceRecords(records, in: db)
        FileManager.default.createFile(atPath: migratedFlag.path, contents: nil)
    }

    private func execute(_ sql: String, in db: OpaquePointer?) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "unknown SQLite error"
            sqlite3_free(errorMessage)
            throw AppError.custom(message)
        }
    }

    private func sqliteError(_ db: OpaquePointer?) -> AppError {
        AppError.custom(String(cString: sqlite3_errmsg(db)))
    }

    private func databaseURL() throws -> URL {
        try appSupportDirectory().appendingPathComponent("probes.sqlite")
    }

    private func legacyJSONURL() throws -> URL {
        try appSupportDirectory().appendingPathComponent("probes.json")
    }

    private func appSupportDirectory() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("Latency Graph for ClashX Meta", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

@available(macOS 12.0, *)
struct ModernContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedHours: Double = 24
    @State private var selectedSidebarPage: String = "overview"
    @State private var navigationDirection: PageNavigationDirection = .downward
    @State private var isSidebarVisible = true

    private var versionedMotionProfile: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: model.runtimeProfile, intensity: model.motionIntensity)
    }

    private var interfaceAnimation: Animation? {
        reduceMotion || model.motionIntensity == .none ? nil : versionedMotionProfile.pageSwitchAnimation
    }

    private var pageTransition: AnyTransition {
        navigationDirection.transition(reduceMotion: reduceMotion, intensity: model.motionIntensity)
    }

    private var sidebarPageOrder: [String] {
        ["settings", "overview"] + model.monitoredProxyNames.map { "node:\($0)" }
    }

    private var controlButtonTitles: [String] {
        [
            model.t("开始监控"),
            model.t("停止监控"),
            model.t("立即探测"),
            model.t("刷新代理列表"),
            model.t("检查更新"),
            model.t("删除历史数据")
        ]
    }

    private var controlButtonWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let widestText = controlButtonTitles
            .map { ceil(($0 as NSString).size(withAttributes: [.font: font]).width) }
            .max() ?? 0
        return widestText + 4
    }

    private var sidebarColumnWidth: CGFloat { 238 }
    private var titlebarContentHeight: CGFloat { 52 }
    private var collapsedTitleLeadingSpacer: CGFloat { 112 }
    private var usesIntegratedTitlebar: Bool { model.runtimeProfile.osFamily == .macOS15OrNewer }
    private var allowsSidebarCollapse: Bool { model.runtimePlan.allowsSidebarCollapse }
    private var usesLegacy15CompatVisuals: Bool {
        model.runtimeProfile.osFamily == .macOS12
    }

    var body: some View {
        HStack(spacing: 0) {
            if isSidebarVisible || !allowsSidebarCollapse {
                sidebarShell
                    .frame(width: sidebarColumnWidth)
                    .transition(allowsSidebarCollapse ? .move(edge: .leading).combined(with: .opacity) : .identity)

                Divider()
            }

            detailShell
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .integratedWindowTitlebar(usesIntegratedTitlebar)
        .frame(minWidth: 1010, minHeight: 760)
        .compatibleTint(model.accentColor)
        .background(legacyCompatWindowBackground)
        .background(MacOS12StatusBarBridge(model: model).frame(width: 0, height: 0))
        .environment(\.locale, model.locale)
        .animation(interfaceAnimation, value: selectedSidebarPage)
        .animation(interfaceAnimation, value: model.languageCode)
        .animation(interfaceAnimation, value: model.accentColorID)
        .animation(interfaceAnimation, value: model.motionIntensityID)
        .versionedStartupMotion(profile: versionedMotionProfile)
    }

    private var sidebarShell: some View {
        VStack(spacing: 0) {
            if usesIntegratedTitlebar {
                HStack(spacing: 10) {
                    Spacer()
                    if allowsSidebarCollapse {
                        sidebarToggleButton
                    }
                    Text(model.t("节点监控"))
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                }
                .frame(height: titlebarContentHeight)
                .background(sidebarBackground)

                Divider()
            }

            sidebarContent
        }
        .background(sidebarBackground)
    }

    private var detailShell: some View {
        VStack(spacing: 0) {
            if usesIntegratedTitlebar {
                HStack {
                    if !isSidebarVisible, allowsSidebarCollapse {
                        Color.clear
                            .frame(width: collapsedTitleLeadingSpacer)
                        sidebarToggleButton
                        Text(model.t("节点监控"))
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                    } else {
                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: titlebarContentHeight)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.96))

                Divider()
            }

            detailContent
        }
    }

    private var sidebarBackground: Color {
        usesLegacy15CompatVisuals
            ? Color(NSColor.windowBackgroundColor).opacity(0.82)
            : Color(NSColor.controlBackgroundColor).opacity(0.92)
    }

    private var legacyCompatWindowBackground: some View {
        Group {
            if usesLegacy15CompatVisuals {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(NSColor.windowBackgroundColor).opacity(0.98),
                        Color(NSColor.controlBackgroundColor).opacity(0.88)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.clear
            }
        }
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(interfaceAnimation) {
                isSidebarVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.leading")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isSidebarVisible ? model.t("隐藏侧栏") : model.t("显示侧栏"))
    }

    private var sidebarContent: some View {
        List {
            Section(model.t("Language")) {
                Picker("", selection: $model.languageCode) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Section(model.t("动态效果")) {
                Picker("", selection: $model.motionIntensityID) {
                    Text(model.t("增强")).tag(MotionIntensity.enhanced.rawValue)
                    Text(model.t("减弱")).tag(MotionIntensity.reduced.rawValue)
                    Text(model.t("无动画")).tag(MotionIntensity.none.rawValue)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Section(model.t("主要颜色")) {
                AccentColorPicker(model: model)
            }

            Section(model.t("设置")) {
                Button {
                    selectPage("settings")
                } label: {
                    HStack {
                        Label(model.t("设置"), systemImage: "slider.horizontal.3")
                        Spacer()
                        if selectedSidebarPage == "settings" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(Legacy15SidebarButtonStyle(isSelected: selectedSidebarPage == "settings", accentColor: model.accentColor))
            }

            Section(model.t("控制")) {
                controlButton(model.isRunning ? model.t("停止监控") : model.t("开始监控"), isProminent: true) {
                    model.isRunning ? model.stopMonitoring() : model.startMonitoring()
                }

                controlButton(model.t("立即探测")) {
                    Task { await model.runProbe() }
                }
                .disabled(model.isTesting)

                controlButton(model.t("刷新代理列表")) {
                    Task { await model.refreshProxyCatalog() }
                }

                controlButton(model.t("检查更新")) {
                    Task { await model.checkForUpdates() }
                }
                .disabled(model.isCheckingForUpdates)

                controlButton(model.t("删除历史数据"), role: .destructive) {
                    model.clearHistory()
                }
            }

            Section(model.t("状态")) {
                SidebarStatusRow(title: model.t("当前节点")) {
                    Text(model.resolvedProxyName)
                }
                SidebarStatusRow(title: model.t("监控节点数")) {
                    Text("\(model.monitoredProxyNames.count)")
                        .monospacedDigit()
                }
                SidebarStatusRow(title: model.t("监控状态")) {
                    Text(model.monitoringStatusText)
                }
                if let error = model.latestError, !error.isEmpty {
                    Text(model.displayError(error))
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                if let updateStatus = model.updateStatus, !updateStatus.isEmpty {
                    Text(updateStatus)
                        .foregroundStyle(model.updateURL == nil ? .secondary : model.accentColor)
                        .font(.footnote)
                    if model.updateURL != nil {
                        Button(model.t("打开下载页")) {
                            model.openUpdatePage()
                        }
                        .buttonStyle(LightweightPressButtonStyle())
                    }
                }
            }

            Section(model.t("Overview")) {
                Button {
                    selectPage("overview")
                } label: {
                    HStack {
                        Label(model.t("Overview"), systemImage: "rectangle.stack")
                        Spacer()
                        if selectedSidebarPage == "overview" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .buttonStyle(Legacy15SidebarButtonStyle(isSelected: selectedSidebarPage == "overview", accentColor: model.accentColor))
            }

            Section(model.t("节点分页")) {
                ForEach(model.monitoredProxyNames, id: \.self) { proxy in
                    Button {
                        selectPage("node:\(proxy)")
                    } label: {
                        HStack {
                            Text(proxy)
                                .lineLimit(1)
                            Spacer()
                            if selectedSidebarPage == "node:\(proxy)" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(Legacy15SidebarButtonStyle(isSelected: selectedSidebarPage == "node:\(proxy)", accentColor: model.accentColor))
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var detailContent: some View {
        GeometryReader { geometry in
            if selectedSidebarPage == "settings" {
                SettingsPage(availableHeight: geometry.size.height)
                    .environmentObject(model)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .id(selectedSidebarPage)
                    .transition(pageTransition)
                    .versionedPageSwitchMotion(profile: versionedMotionProfile, pageID: selectedSidebarPage, direction: navigationDirection)
                    .coordinateSpace(name: "detailScroll")
            } else if selectedSidebarPage.hasPrefix("node:") {
                let proxyName = String(selectedSidebarPage.dropFirst("node:".count))
                NodePageView(
                    proxyName: proxyName,
                    selectedHours: $selectedHours,
                    availableHeight: geometry.size.height,
                    navigationDirection: navigationDirection
                )
                .environmentObject(model)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .id(selectedSidebarPage)
                .transition(pageTransition)
                .versionedPageSwitchMotion(profile: versionedMotionProfile, pageID: selectedSidebarPage, direction: navigationDirection)
                .coordinateSpace(name: "detailScroll")
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        Color.clear
                            .frame(height: 0)
                            .id("detailTop")

                        OverviewPage(selectedHours: $selectedHours, navigationDirection: navigationDirection)
                            .environmentObject(model)
                            .padding(20)
                            .id(selectedSidebarPage)
                            .transition(pageTransition)
                    }
                    .versionedPageSwitchMotion(profile: versionedMotionProfile, pageID: selectedSidebarPage, direction: navigationDirection)
                    .coordinateSpace(name: "detailScroll")
                    .onChange(of: selectedSidebarPage) { _ in
                        withAnimation(interfaceAnimation) {
                            scrollProxy.scrollTo("detailTop", anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private func selectPage(_ page: String) {
        guard page != selectedSidebarPage else { return }
        let currentIndex = sidebarPageOrder.firstIndex(of: selectedSidebarPage) ?? 0
        let nextIndex = sidebarPageOrder.firstIndex(of: page) ?? currentIndex
        navigationDirection = nextIndex >= currentIndex ? .downward : .upward
        withAnimation(interfaceAnimation) {
            selectedSidebarPage = page
        }
    }

    private func controlButton(_ title: String, role: ButtonRole? = nil, isProminent: Bool = false, action: @escaping () -> Void) -> some View {
        Group {
            if isProminent {
                Button(role: role, action: action) {
                    Text(title)
                        .frame(width: controlButtonWidth)
                }
                .buttonStyle(Legacy15ControlButtonStyle(isProminent: true, accentColor: model.accentColor))
            } else {
                Button(role: role, action: action) {
                    Text(title)
                        .frame(width: controlButtonWidth)
                }
                .buttonStyle(Legacy15ControlButtonStyle(isProminent: false, accentColor: model.accentColor))
            }
        }
        .compatibleTint(model.accentColor)
    }
}

@available(macOS 13.0, *)
struct NativeModernContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedHours: Double = 24
    @State private var selectedSidebarPage: String = "overview"
    @State private var navigationDirection: PageNavigationDirection = .downward

    private var versionedMotionProfile: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: model.runtimeProfile, intensity: model.motionIntensity)
    }

    private var interfaceAnimation: Animation? {
        reduceMotion || model.motionIntensity == .none ? nil : versionedMotionProfile.pageSwitchAnimation
    }

    private var pageTransition: AnyTransition {
        navigationDirection.transition(reduceMotion: reduceMotion, intensity: model.motionIntensity)
    }

    private var sidebarPageOrder: [String] {
        ["settings", "overview"] + model.monitoredProxyNames.map { "node:\($0)" }
    }

    private var controlButtonTitles: [String] {
        [
            model.t("开始监控"),
            model.t("停止监控"),
            model.t("立即探测"),
            model.t("刷新代理列表"),
            model.t("检查更新"),
            model.t("删除历史数据")
        ]
    }

    private var controlButtonWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let widestText = controlButtonTitles
            .map { ceil(($0 as NSString).size(withAttributes: [.font: font]).width) }
            .max() ?? 0
        return widestText + 24
    }

    var body: some View {
        NavigationSplitView {
            List {
                Section(model.t("Language")) {
                    Picker("", selection: $model.languageCode) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                Section(model.t("动态效果")) {
                    Picker("", selection: $model.motionIntensityID) {
                        Text(model.t("增强")).tag(MotionIntensity.enhanced.rawValue)
                        Text(model.t("减弱")).tag(MotionIntensity.reduced.rawValue)
                        Text(model.t("无动画")).tag(MotionIntensity.none.rawValue)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                Section(model.t("主要颜色")) {
                    AccentColorPicker(model: model)
                }

                Section(model.t("设置")) {
                    Button {
                        selectPage("settings")
                    } label: {
                        HStack {
                            Label(model.t("设置"), systemImage: "slider.horizontal.3")
                            Spacer()
                            if selectedSidebarPage == "settings" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(VersionedPagePressButtonStyle(isSelected: selectedSidebarPage == "settings", accentColor: model.accentColor, profile: versionedMotionProfile))
                }

                Section(model.t("控制")) {
                    controlButton(model.isRunning ? model.t("停止监控") : model.t("开始监控"), isProminent: true) {
                        model.isRunning ? model.stopMonitoring() : model.startMonitoring()
                    }

                    controlButton(model.t("立即探测")) {
                        Task { await model.runProbe() }
                    }
                    .disabled(model.isTesting)

                    controlButton(model.t("刷新代理列表")) {
                        Task { await model.refreshProxyCatalog() }
                    }

                    controlButton(model.t("检查更新")) {
                        Task { await model.checkForUpdates() }
                    }
                    .disabled(model.isCheckingForUpdates)

                    controlButton(model.t("删除历史数据"), role: .destructive) {
                        model.clearHistory()
                    }
                }

                Section(model.t("状态")) {
                    LabeledContent(model.t("当前节点")) {
                        Text(model.resolvedProxyName)
                    }
                    LabeledContent(model.t("监控节点数")) {
                        Text("\(model.monitoredProxyNames.count)")
                            .monospacedDigit()
                    }
                    LabeledContent(model.t("监控状态")) {
                        Text(model.monitoringStatusText)
                    }
                    if let error = model.latestError, !error.isEmpty {
                        Text(model.displayError(error))
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                    if let updateStatus = model.updateStatus, !updateStatus.isEmpty {
                        Text(updateStatus)
                            .foregroundStyle(model.updateURL == nil ? .secondary : model.accentColor)
                            .font(.footnote)
                        if model.updateURL != nil {
                            Button(model.t("打开下载页")) {
                                model.openUpdatePage()
                            }
                            .buttonStyle(LightweightPressButtonStyle())
                        }
                    }
                }

                Section(model.t("Overview")) {
                    Button {
                        selectPage("overview")
                    } label: {
                        HStack {
                            Label(model.t("Overview"), systemImage: "rectangle.stack")
                            Spacer()
                            if selectedSidebarPage == "overview" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(VersionedPagePressButtonStyle(isSelected: selectedSidebarPage == "overview", accentColor: model.accentColor, profile: versionedMotionProfile))
                }

                Section(model.t("节点分页")) {
                    ForEach(model.monitoredProxyNames, id: \.self) { proxy in
                        Button {
                            selectPage("node:\(proxy)")
                        } label: {
                            HStack {
                                Text(proxy)
                                    .lineLimit(1)
                                Spacer()
                                if selectedSidebarPage == "node:\(proxy)" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .buttonStyle(VersionedPagePressButtonStyle(isSelected: selectedSidebarPage == "node:\(proxy)", accentColor: model.accentColor, profile: versionedMotionProfile))
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Latency Graph for ClashX Meta")
            .navigationSplitViewColumnWidth(min: 248, ideal: 272, max: 330)
        } detail: {
            GeometryReader { geometry in
                if selectedSidebarPage == "settings" {
                    SettingsPage(availableHeight: geometry.size.height)
                        .environmentObject(model)
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .id(selectedSidebarPage)
                        .transition(pageTransition)
                        .versionedPageSwitchMotion(profile: versionedMotionProfile, pageID: selectedSidebarPage, direction: navigationDirection)
                        .coordinateSpace(name: "detailScroll")
                } else if selectedSidebarPage.hasPrefix("node:") {
                    let proxyName = String(selectedSidebarPage.dropFirst("node:".count))
                    NodePageView(
                        proxyName: proxyName,
                        selectedHours: $selectedHours,
                        availableHeight: geometry.size.height,
                        navigationDirection: navigationDirection
                    )
                    .environmentObject(model)
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .id(selectedSidebarPage)
                    .transition(pageTransition)
                    .versionedPageSwitchMotion(profile: versionedMotionProfile, pageID: selectedSidebarPage, direction: navigationDirection)
                    .coordinateSpace(name: "detailScroll")
                } else {
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            Color.clear
                                .frame(height: 0)
                                .id("detailTop")

                            OverviewPage(selectedHours: $selectedHours, navigationDirection: navigationDirection)
                                .environmentObject(model)
                                .padding(20)
                                .id(selectedSidebarPage)
                                .transition(pageTransition)
                        }
                        .versionedPageSwitchMotion(profile: versionedMotionProfile, pageID: selectedSidebarPage, direction: navigationDirection)
                        .coordinateSpace(name: "detailScroll")
                        .onChange(of: selectedSidebarPage) { _ in
                            withAnimation(interfaceAnimation) {
                                scrollProxy.scrollTo("detailTop", anchor: .top)
                            }
                        }
                    }
                }
            }
            .navigationTitle(model.t("节点监控"))
        }
        .frame(minWidth: 1100, minHeight: 760)
        .tint(model.accentColor)
        .environment(\.locale, model.locale)
        .animation(interfaceAnimation, value: selectedSidebarPage)
        .animation(interfaceAnimation, value: model.languageCode)
        .animation(interfaceAnimation, value: model.accentColorID)
        .animation(interfaceAnimation, value: model.motionIntensityID)
        .versionedStartupMotion(profile: versionedMotionProfile)
    }

    private func selectPage(_ page: String) {
        guard page != selectedSidebarPage else { return }
        let currentIndex = sidebarPageOrder.firstIndex(of: selectedSidebarPage) ?? 0
        let nextIndex = sidebarPageOrder.firstIndex(of: page) ?? currentIndex
        navigationDirection = nextIndex >= currentIndex ? .downward : .upward
        withAnimation(interfaceAnimation) {
            selectedSidebarPage = page
        }
    }

    private func controlButton(_ title: String, role: ButtonRole? = nil, isProminent: Bool = false, action: @escaping () -> Void) -> some View {
        Group {
            if isProminent {
                Button(role: role, action: action) {
                    Text(title)
                        .frame(width: controlButtonWidth)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(role: role, action: action) {
                    Text(title)
                        .frame(width: controlButtonWidth)
                }
                .buttonStyle(.bordered)
            }
        }
        .tint(model.accentColor)
    }
}

@available(macOS 12.0, *)
struct AccentColorPicker: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 16), spacing: 7), count: 8)
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
            ForEach(AccentColorOption.all) { option in
                Button {
                    withAnimation(reduceMotion ? nil : MotionTokens.color) {
                        model.accentColorID = option.id
                    }
                } label: {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(option.color)
                        .frame(height: 14)
                            .overlay {
                                if model.accentColorID == option.id {
                                    Capsule(style: .continuous)
                                        .strokeBorder(.primary.opacity(0.9), lineWidth: 1.5)
                                        .overlay {
                                            Capsule(style: .continuous)
                                                .strokeBorder(.white.opacity(0.9), lineWidth: 0.8)
                                        }
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
                    .contentShape(Rectangle())
                    .accessibilityLabel(option.name(for: model.language))
                }
                .buttonStyle(LightweightPressButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(macOS 12.0, *)
struct SidebarStatusRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
            Spacer(minLength: 8)
            content
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

@available(macOS 12.0, *)
struct OverviewPage: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selectedHours: Double
    let navigationDirection: PageNavigationDirection

    private var versionedMotionProfile: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: model.runtimeProfile, intensity: model.motionIntensity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.t("节点概览"))
                .font(.title2.bold())
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "overview", direction: navigationDirection)

            ForEach(model.monitoredProxyNames, id: \.self) { proxyName in
                NodeStatsOverviewRow(proxyName: proxyName)
                    .padding(.bottom, 8)
                    .versionedComponentAppear(profile: versionedMotionProfile, pageID: "overview", direction: navigationDirection)
            }

            combinedChartSection
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "overview", direction: navigationDirection, isChart: true)
        }
    }

    private var combinedChartSection: some View {
        let records = model.chartData(
            hours: selectedHours,
            proxies: model.monitoredProxyNames,
            maxTotalPoints: model.overviewChartPointBudget(hours: selectedHours, seriesCount: model.monitoredProxyNames.count),
            minimumPointsPerSeries: model.runtimeProfile.minimumOverviewPointsPerSeries
        )
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(model.t("合并延迟曲线")) · \(model.t("所有选择节点"))")
                    .font(.title3.bold())
                Spacer()
                TimeRangePicker(selectedHours: $selectedHours, model: model)
            }

            MultiLatencyChart(records: records, proxyNames: model.monitoredProxyNames)
                .frame(height: 320)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .interactivePanel(accentColor: model.accentColor)
                .overlay {
                    if records.isEmpty {
                        EmptyChartOverlay(model: model)
                    }
                }
        }
    }
}

@available(macOS 12.0, *)
struct NodePageView: View {
    @EnvironmentObject private var model: AppModel
    let proxyName: String
    @Binding var selectedHours: Double
    var availableHeight: CGFloat? = nil
    let navigationDirection: PageNavigationDirection
    @State private var latestRecordsTableHeight: CGFloat = 180

    private var versionedMotionProfile: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: model.runtimeProfile, intensity: model.motionIntensity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerCards
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "node:\(proxyName)", direction: navigationDirection)
            chartSection
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "node:\(proxyName)", direction: navigationDirection, isChart: true)
            latestRecordsSection
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "node:\(proxyName)", direction: navigationDirection)
        }
    }

    private var headerCards: some View {
        let stats = model.stats(for: proxyName)
        return HStack(spacing: 12) {
            StatCard(title: model.t("上次延迟"), value: stats.lastLatency.map { "\($0) ms" } ?? "--", compact: true)
            StatCard(title: model.t("24h 平均延迟"), value: stats.avgLatency24h.map { String(format: "%.1f ms", $0) } ?? "--", compact: true)
            StatCard(title: model.t("24h 最高延迟"), value: stats.maxLatency24h.map { "\($0) ms" } ?? "--", compact: true)
            StatCard(title: model.t("24h 丢包率"), value: String(format: "%.1f%%", stats.packetLoss24h * 100), compact: true)
            StatCard(title: model.t("24h 可用率"), value: String(format: "%.1f%%", stats.availability24h * 100), compact: true)
        }
    }

    private var chartSection: some View {
        let records = model.chartData(
            hours: selectedHours,
            proxy: proxyName,
            maxTotalPoints: model.nodeChartPointBudget(hours: selectedHours),
            minimumPointsPerSeries: model.nodeChartPointBudget(hours: selectedHours)
        )
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(model.t("延迟曲线")) · \(proxyName)")
                    .font(.title3.bold())
                Spacer()
                TimeRangePicker(selectedHours: $selectedHours, model: model)
            }

            LatencyChart(
                records: records,
                color: model.accentColor,
                maxRenderedPoints: model.nodeChartPointBudget(hours: selectedHours)
            )
                .frame(height: 320)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .interactivePanel(accentColor: model.accentColor)
                .overlay {
                    if records.isEmpty {
                        EmptyChartOverlay(model: model)
                    }
                }
        }
    }

    private var latestRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let pageRecords = model.recentRecords(for: proxyName, limit: 100)

            HStack {
                Text(model.t("最近记录"))
                    .font(.title3.bold())
                Spacer()
                Button(model.t("清空历史")) {
                    model.clearHistory(for: proxyName)
                }
                .buttonStyle(.bordered)
            }

            RecentRecordsTable(records: pageRecords, model: model)
            .frame(height: latestRecordsTableHeight)
            .background {
                GeometryReader { geometry in
                    let minY = geometry.frame(in: .named("detailScroll")).minY
                    Color.clear
                        .onAppear {
                            updateLatestRecordsTableHeight(from: minY)
                        }
                        .onChange(of: minY) { nextMinY in
                            updateLatestRecordsTableHeight(from: nextMinY)
                        }
                        .onChange(of: availableHeight ?? 0) { _ in
                            updateLatestRecordsTableHeight(from: minY)
                        }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.22), lineWidth: 1)
            }
            .interactivePanel(cornerRadius: 14, accentColor: model.accentColor)
        }
    }

    private func updateLatestRecordsTableHeight(from minY: CGFloat) {
        guard let availableHeight else { return }
        let bottomPadding: CGFloat = 28
        let nextHeight = max(120, availableHeight - minY - bottomPadding)
        guard abs(latestRecordsTableHeight - nextHeight) > 0.5 else { return }
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                latestRecordsTableHeight = nextHeight
            }
        }
    }
}

@available(macOS 12.0, *)
struct RecentRecordsTable: View {
    let records: [ProbeRecord]
    let model: AppModel

    private let horizontalPadding: CGFloat = 14
    private let columnSpacing: CGFloat = 12
    private let timeWidth: CGFloat = 172
    private let nodeWidth: CGFloat = 280

    var body: some View {
        VStack(spacing: 0) {
            tableHeader
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 9)
                .background(Color.secondary.opacity(0.08))

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(records) { record in
                        recordRow(record)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, 8)
                        Divider()
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: columnSpacing) {
            headerText(model.t("时间"))
                .frame(width: timeWidth, alignment: .leading)
            headerText(model.t("节点"))
                .frame(width: nodeWidth, alignment: .leading)
            headerText(model.t("结果"))
                .frame(maxWidth: .infinity, alignment: .leading)
            headerText(model.t("延迟"))
                .frame(maxWidth: .infinity, alignment: .leading)
            headerText(model.t("说明"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func recordRow(_ record: ProbeRecord) -> some View {
        HStack(spacing: columnSpacing) {
            Text(record.timestamp, format: .dateTime.month().day().hour().minute().second())
                .frame(width: timeWidth, alignment: .leading)
            Text(record.proxyName)
                .frame(width: nodeWidth, alignment: .leading)
            Text(record.success ? model.t("成功") : model.t("失败"))
                .foregroundStyle(record.success ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(record.latencyMs.map { "\($0) ms" } ?? "--")
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(record.errorDescription.map(model.displayError) ?? "")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)
        .lineLimit(1)
        .truncationMode(.tail)
    }

    private func headerText(_ value: String) -> some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

@available(macOS 12.0, *)
struct NodeStatsOverviewRow: View {
    @EnvironmentObject private var model: AppModel
    let proxyName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(proxyName)
                .font(.title3.bold())
            statsCards
        }
    }

    private var statsCards: some View {
        let stats = model.stats(for: proxyName)
        return HStack(spacing: 12) {
            StatCard(title: model.t("上次延迟"), value: stats.lastLatency.map { "\($0) ms" } ?? "--", compact: true)
            StatCard(title: model.t("24h 平均延迟"), value: stats.avgLatency24h.map { String(format: "%.1f ms", $0) } ?? "--", compact: true)
            StatCard(title: model.t("24h 最高延迟"), value: stats.maxLatency24h.map { "\($0) ms" } ?? "--", compact: true)
            StatCard(title: model.t("24h 丢包率"), value: String(format: "%.1f%%", stats.packetLoss24h * 100), compact: true)
            StatCard(title: model.t("24h 可用率"), value: String(format: "%.1f%%", stats.availability24h * 100), compact: true)
        }
    }
}

@available(macOS 12.0, *)
struct SettingsPage: View {
    @EnvironmentObject private var model: AppModel
    var availableHeight: CGFloat? = nil

    private var versionedMotionProfile: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: model.runtimeProfile, intensity: model.motionIntensity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.t("设置"))
                .font(.title2.bold())
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "settings", direction: .unchanged)
            SettingsPanel(model: model, availableHeight: availableHeight)
                .versionedComponentAppear(profile: versionedMotionProfile, pageID: "settings", direction: .unchanged)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

@available(macOS 12.0, *)
struct TimeRangePicker: View {
    @Binding var selectedHours: Double
    @ObservedObject var model: AppModel

    var body: some View {
        Picker(model.t("时间范围"), selection: $selectedHours) {
            Text("1h").tag(1.0)
            Text("4h").tag(4.0)
            Text("12h").tag(12.0)
            Text("24h").tag(24.0)
            Text("7d").tag(168.0)
            Text("1m").tag(720.0)
            Text("3m").tag(2160.0)
        }
        .pickerStyle(.segmented)
        .frame(width: 460)
    }
}

@available(macOS 12.0, *)
struct EmptyChartOverlay: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.largeTitle)
            Text(model.t("还没有延迟数据"))
                .font(.headline)
            Text(model.t("点击“开始监控”或“立即探测”后，这里会开始画曲线。"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.secondary)
    }
}

@available(macOS 12.0, *)
struct SettingsPanel: View {
    @ObservedObject var model: AppModel
    var availableHeight: CGFloat? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedHistoryProxyName = ""

    private var settingsAnimation: Animation? {
        reduceMotion ? nil : MotionTokens.soft
    }

    private var manualProxyChoices: [String] {
        Array(Set(model.availableProxies + model.selectedManualProxyNames)).sorted()
    }

    private var historyProxyChoices: [String] {
        uniqueChoices(model.monitoredProxyNames + model.selectedManualProxyNames + model.availableProxies)
    }

    private var activeHistoryProxyName: String {
        if !selectedHistoryProxyName.isEmpty, historyProxyChoices.contains(selectedHistoryProxyName) {
            return selectedHistoryProxyName
        }
        return historyProxyChoices.first ?? ""
    }

    private var controllerURLChoices: [String] {
        uniqueChoices([
            model.controllerURL,
            "http://127.0.0.1:9090",
            "http://localhost:9090",
            "http://127.0.0.1:7890"
        ])
    }

    private var targetURLChoices: [String] {
        uniqueChoices([
            model.targetURL,
            "https://www.gstatic.com/generate_204",
            "https://cp.cloudflare.com/generate_204",
            "https://www.google.com/generate_204",
            "https://connectivitycheck.gstatic.com/generate_204"
        ])
    }

    private let probeIntervalChoices = [5000, 10000, 30000, 60000, 120000]
    private let probeSampleCountChoices = [1, 2, 3, 4, 5]

    var body: some View {
        GeometryReader { geometry in
            settingsRows(manualProxyListHeight: manualProxyListHeight(for: geometry.size.height))
        }
    }

    private func settingsRows(manualProxyListHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSection(title: model.t("连接与认证"), index: 0) {
                controllerURLRow
                secretRow
            }

            settingsSection(title: model.t("监控节点"), index: 1) {
                monitorAllRow
                followGroupRow
                proxyGroupRow
                manualProxyRow(height: manualProxyListHeight)
            }

            settingsSection(title: model.t("探测参数"), index: 2) {
                targetURLRow
                dataPointIntervalRow
                delayTimeoutRow
                probeSampleCountRow
            }

            settingsSection(title: model.t("数据库管理"), index: 3) {
                databaseSummaryRow
                databaseActionsRow
            }
        }
        .onChange(of: model.useSelectedProxyFromGroup) { _ in
            Task { await model.refreshProxyCatalog() }
        }
        .onChange(of: model.monitorAllProxiesInGroup) { _ in
            Task { await model.refreshProxyCatalog() }
        }
        .onChange(of: model.probeIntervalMs) { _ in
            model.rescheduleMonitoringIfNeeded()
        }
        .animation(settingsAnimation, value: model.useSelectedProxyFromGroup)
        .animation(settingsAnimation, value: model.monitorAllProxiesInGroup)
        .animation(settingsAnimation, value: model.probeIntervalMs)
        .animation(settingsAnimation, value: model.probeSampleCount)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func manualProxyListHeight(for panelHeight: CGFloat) -> CGFloat {
        let fixedContentHeight: CGFloat = 552
        let bottomPadding: CGFloat = 4
        return max(52, panelHeight - fixedContentHeight - bottomPadding)
    }

    private func settingsSection<Content: View>(title: String, index: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .settingsSolidCard(accentColor: model.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .staggeredGroupAppear(index: index)
    }

    private var controllerURLRow: some View {
        SettingsRow(title: model.t("Controller URL")) {
            HStack {
                Picker(model.t("Controller URL"), selection: $model.controllerURL) {
                    ForEach(controllerURLChoices, id: \.self) { url in
                        Text(url).tag(url)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Button(model.t("从剪贴板读取")) {
                    pasteString(into: \.controllerURL)
                }
            }
        }
    }

    private var secretRow: some View {
        SettingsRow(title: model.t("Secret")) {
            HStack {
                Text(model.controllerSecret.isEmpty ? model.t("未设置") : model.t("已设置"))
                    .foregroundStyle(.secondary)
                Button(model.t("从剪贴板读取")) {
                    pasteString(into: \.controllerSecret)
                }
                Button(model.t("清空")) {
                    model.controllerSecret = ""
                }
            }
        }
    }

    private var monitorAllRow: some View {
        SettingsRow(title: "") {
            Toggle(model.t("自动监控代理组所有节点"), isOn: $model.monitorAllProxiesInGroup)
        }
    }

    private var followGroupRow: some View {
        SettingsRow(title: "") {
            Toggle(model.t("跟随代理组当前节点"), isOn: $model.useSelectedProxyFromGroup)
                .disabled(model.monitorAllProxiesInGroup)
        }
    }

    private var proxyGroupRow: some View {
        SettingsRow(title: model.t("代理组")) {
            Picker(model.t("代理组"), selection: $model.proxyGroupName) {
                ForEach(model.availableProxyGroups, id: \.self) { group in
                    Text(group).tag(group)
                }
            }
            .disabled(!model.useSelectedProxyFromGroup && !model.monitorAllProxiesInGroup)
        }
    }

    private func manualProxyRow(height: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.t("手动多选节点"))
                Text(model.t("勾选多个节点后，每轮采样都会分别记录，并在左侧节点分页中逐页查看。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 160, alignment: .leading)

            manualProxySelectionList(height: height)
        }
    }

    private var targetURLRow: some View {
        SettingsRow(title: model.t("探测目标")) {
            HStack {
                Picker(model.t("探测目标"), selection: $model.targetURL) {
                    ForEach(targetURLChoices, id: \.self) { url in
                        Text(url).tag(url)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Button(model.t("从剪贴板读取")) {
                    pasteString(into: \.targetURL)
                }
            }
        }
    }

    private var dataPointIntervalRow: some View {
        SettingsRow(title: model.t("数据点间隔")) {
            HStack {
                Picker(model.t("数据点间隔"), selection: $model.probeIntervalMs) {
                    ForEach(probeIntervalChoices, id: \.self) { interval in
                        Text("\(interval)").tag(interval)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                Text("ms")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var delayTimeoutRow: some View {
        SettingsRow(title: model.t("测速超时")) {
            Stepper(value: $model.delayTimeoutMs, in: 1000 ... 30000, step: 500) {
                Text("\(model.delayTimeoutMs) ms")
            }
        }
    }

    private var probeSampleCountRow: some View {
        SettingsRow(title: model.t("每点探测次数")) {
            HStack {
                Picker(model.t("每点探测次数"), selection: $model.probeSampleCount) {
                    ForEach(probeSampleCountChoices, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                Text(model.t("次，取最小值"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var databaseSummaryRow: some View {
        SettingsRow(title: model.t("数据库")) {
            HStack(spacing: 16) {
                Text(model.databaseSizeText)
                    .monospacedDigit()
                Text("\(model.t("记录数")) \(model.databaseRecordCountText)")
                    .foregroundStyle(.secondary)
                Text("\(model.t("保留策略")) \(model.retentionPolicyText)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var databaseActionsRow: some View {
        SettingsRow(title: model.t("历史管理")) {
            HStack(spacing: 10) {
                Picker(model.t("节点"), selection: Binding(
                    get: { activeHistoryProxyName },
                    set: { selectedHistoryProxyName = $0 }
                )) {
                    ForEach(historyProxyChoices, id: \.self) { proxy in
                        Text(proxy).tag(proxy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
                .disabled(historyProxyChoices.isEmpty)

                Button(model.t("清理此节点")) {
                    model.clearHistory(for: activeHistoryProxyName)
                }
                .disabled(activeHistoryProxyName.isEmpty)

                Button(model.t("导出 CSV")) {
                    model.exportHistoryCSV()
                }
                .disabled(model.records.isEmpty)
            }
            if let message = model.databaseStatusMessage, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func manualProxySelectionList(height: CGFloat) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(manualProxyChoices, id: \.self) { proxy in
                    Toggle(
                        proxy,
                        isOn: Binding(
                            get: { model.selectedManualProxyNames.contains(proxy) },
                            set: { model.setManualProxy(proxy, isSelected: $0) }
                        )
                    )
                    .toggleStyle(.checkbox)
                    .lineLimit(1)
                }

                if manualProxyChoices.isEmpty {
                    Text(model.t("点击“刷新代理列表”后选择节点。"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: height)
        .padding(8)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        .disabled(model.useSelectedProxyFromGroup || model.monitorAllProxiesInGroup)
    }

    private func pasteString(into keyPath: ReferenceWritableKeyPath<AppModel, String>) {
        guard let string = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !string.isEmpty
        else {
            return
        }
        model[keyPath: keyPath] = string
    }

    private func uniqueChoices(_ choices: [String]) -> [String] {
        var seen = Set<String>()
        return choices.compactMap { choice in
            let trimmed = choice.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else {
                return nil
            }
            seen.insert(trimmed)
            return trimmed
        }
    }
}

@available(macOS 12.0, *)
struct SettingsRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if title.isEmpty {
                Spacer(minLength: 0)
                    .frame(width: 160)
            } else {
                Text(title)
                    .frame(width: 160, alignment: .leading)
            }
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@available(macOS 12.0, *)
struct LatencyChart: View {
    let records: [ProbeRecord]
    let color: Color
    var maxRenderedPoints: Int = 700

    private func nativePointBudget(width: CGFloat) -> Int {
        let widthBudget = max(220, Int(width * 0.46))
        return min(maxRenderedPoints, widthBudget)
    }

    var body: some View {
        if #available(macOS 13.0, *) {
            GeometryReader { geometry in
                let budget = nativePointBudget(width: geometry.size.width)
                let renderedRecords = ChartDownsampler.reduce(
                    records,
                    maxTotalPoints: budget,
                    minimumPointsPerSeries: budget
                )
                let showsDenseDecorations = renderedRecords.count <= 180

                ModernLatencyChart(
                    records: renderedRecords,
                    color: color,
                    showsDenseBars: showsDenseDecorations,
                    showsArea: showsDenseDecorations
                )
            }
        } else {
            let renderedRecords = ChartDownsampler.reduce(
                records,
                maxTotalPoints: maxRenderedPoints,
                minimumPointsPerSeries: maxRenderedPoints
            )
            PathLatencyChart(
                records: renderedRecords,
                series: [ChartSeriesStyle(proxyName: nil, color: color)],
                showsBars: renderedRecords.count <= 360,
                showsAxes: true,
                showsArea: true
            )
        }
    }

}

@available(macOS 12.0, *)
struct MenuLatencySparkline: View {
    let records: [ProbeRecord]
    let color: Color

    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                ModernMenuLatencySparkline(records: records, color: color)
            } else {
                PathLatencyChart(
                    records: records,
                    series: [ChartSeriesStyle(proxyName: nil, color: color)],
                    showsBars: records.count <= 160,
                    showsAxes: false,
                    showsArea: true
                )
            }
        }
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
    }
}

@available(macOS 12.0, *)
struct MultiLatencyChart: View {
    let records: [ProbeRecord]
    let proxyNames: [String]

    private func nativePerSeriesBudget(width: CGFloat) -> Int {
        let seriesCount = max(proxyNames.count, 1)
        let perSeriesWidth = width / CGFloat(seriesCount)
        return max(120, min(320, Int(perSeriesWidth * 1.1)))
    }

    private func color(for proxyName: String) -> Color {
        let palette = AccentColorOption.all.map(\.color)
        guard let index = proxyNames.firstIndex(of: proxyName), !palette.isEmpty else {
            return .purple
        }
        return palette[index % palette.count]
    }

    var body: some View {
        if #available(macOS 13.0, *) {
            GeometryReader { geometry in
                let perSeriesBudget = nativePerSeriesBudget(width: geometry.size.width)
                let renderedRecords = ChartDownsampler.reduce(
                    records,
                    maxTotalPoints: perSeriesBudget * max(proxyNames.count, 1),
                    minimumPointsPerSeries: perSeriesBudget
                )
                ModernMultiLatencyChart(records: renderedRecords, proxyNames: proxyNames)
            }
        } else {
            PathLatencyChart(
                records: records,
                series: proxyNames.map { ChartSeriesStyle(proxyName: $0, color: color(for: $0)) },
                showsBars: false,
                showsAxes: true,
                showsArea: false
            )
        }
    }

}

private struct ChartSeriesStyle: Identifiable {
    let id: String
    let proxyName: String?
    let color: Color

    init(proxyName: String?, color: Color) {
        self.id = proxyName ?? "__single_series"
        self.proxyName = proxyName
        self.color = color
    }
}

private struct PathLatencyChartMetrics {
    let successfulRecords: [ProbeRecord]
    let successfulRecordsByProxy: [String: [ProbeRecord]]
    let failureRecords: [ProbeRecord]
    let timeRange: ClosedRange<Date>?
    let yAxisMax: Int

    init(records: [ProbeRecord]) {
        var successes: [ProbeRecord] = []
        var failures: [ProbeRecord] = []
        var minTimestamp: Date?
        var maxTimestamp: Date?
        var maxLatency = 1

        successes.reserveCapacity(records.count)
        failures.reserveCapacity(records.count / 8)

        for record in records {
            minTimestamp = minTimestamp.map { min($0, record.timestamp) } ?? record.timestamp
            maxTimestamp = maxTimestamp.map { max($0, record.timestamp) } ?? record.timestamp

            if record.success, let latency = record.latencyMs {
                successes.append(record)
                maxLatency = max(maxLatency, latency)
            } else if !record.success {
                failures.append(record)
            }
        }

        let sortedSuccesses = successes.sorted { $0.timestamp < $1.timestamp }
        self.successfulRecords = sortedSuccesses
        self.successfulRecordsByProxy = Dictionary(grouping: sortedSuccesses, by: \.proxyName)
        self.failureRecords = failures
        self.yAxisMax = Self.roundedYAxisMax(for: maxLatency)

        if let minTimestamp, let maxTimestamp {
            self.timeRange = minTimestamp == maxTimestamp
                ? minTimestamp.addingTimeInterval(-30) ... maxTimestamp.addingTimeInterval(30)
                : minTimestamp ... maxTimestamp
        } else {
            self.timeRange = nil
        }
    }

    private static func roundedYAxisMax(for raw: Int) -> Int {
        if raw <= 60 { return 60 }
        if raw <= 150 { return 150 }
        if raw <= 300 { return 300 }
        if raw <= 600 { return 600 }
        if raw <= 900 { return 900 }
        let rounded = Int(ceil(Double(raw) / 500.0) * 500.0)
        return max(rounded, raw)
    }
}

private struct PathLatencyChart: View {
    private let metrics: PathLatencyChartMetrics
    let series: [ChartSeriesStyle]
    let showsBars: Bool
    let showsAxes: Bool
    let showsArea: Bool

    private let leftAxisWidth: CGFloat = 52
    private let bottomAxisHeight: CGFloat = 28
    private let topPadding: CGFloat = 8
    private let rightPadding: CGFloat = 8

    private static let axisDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()

    init(records: [ProbeRecord], series: [ChartSeriesStyle], showsBars: Bool, showsAxes: Bool, showsArea: Bool) {
        self.metrics = PathLatencyChartMetrics(records: records)
        self.series = series
        self.showsBars = showsBars
        self.showsAxes = showsAxes
        self.showsArea = showsArea
    }

    var body: some View {
        GeometryReader { geometry in
            let plotRect = CGRect(
                x: showsAxes ? leftAxisWidth : 0,
                y: topPadding,
                width: max(1, geometry.size.width - (showsAxes ? leftAxisWidth : 0) - rightPadding),
                height: max(1, geometry.size.height - topPadding - (showsAxes ? bottomAxisHeight : 0))
            )

            ZStack(alignment: .topLeading) {
                gridPath(in: plotRect)
                    .stroke(Color.secondary.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                baselinePath(in: plotRect)
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 1)

                ForEach(effectiveSeries) { style in
                    let points = coordinates(for: style, in: plotRect, metrics: metrics)

                    if showsArea {
                        areaPath(points: points, plotRect: plotRect)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [style.color.opacity(0.28), style.color.opacity(0.035)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    if showsBars {
                        barsPath(points: points, plotRect: plotRect)
                            .stroke(style.color.opacity(0.22), lineWidth: 2)
                    }

                    linePath(points: points)
                        .stroke(style.color, style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                }

                failuresPath(in: plotRect, metrics: metrics)
                    .stroke(Color.red.opacity(0.36), lineWidth: 1.2)

                if showsAxes {
                    axisOverlay(plotRect: plotRect, metrics: metrics)
                }
            }
        }
    }

    private var effectiveSeries: [ChartSeriesStyle] {
        series.isEmpty ? [ChartSeriesStyle(proxyName: nil, color: .purple)] : series
    }

    private func records(for style: ChartSeriesStyle, metrics: PathLatencyChartMetrics) -> [ProbeRecord] {
        if let proxyName = style.proxyName {
            return metrics.successfulRecordsByProxy[proxyName, default: []]
        }
        return metrics.successfulRecords
    }

    private func coordinates(for style: ChartSeriesStyle, in plotRect: CGRect, metrics: PathLatencyChartMetrics) -> [CGPoint] {
        guard let timeRange = metrics.timeRange else { return [] }
        return records(for: style, metrics: metrics).compactMap { record in
            guard let latency = record.latencyMs else { return nil }
            return CGPoint(
                x: xPosition(for: record.timestamp, in: plotRect, timeRange: timeRange),
                y: yPosition(for: latency, in: plotRect, yAxisMax: metrics.yAxisMax)
            )
        }
    }

    private func gridPath(in plotRect: CGRect) -> Path {
        Path { path in
            for index in 1 ... 3 {
                let progress = CGFloat(index) / 3
                let y = plotRect.maxY - plotRect.height * progress
                path.move(to: CGPoint(x: plotRect.minX, y: y))
                path.addLine(to: CGPoint(x: plotRect.maxX, y: y))
            }

            for index in 0 ... 6 {
                let progress = CGFloat(index) / 6
                let x = plotRect.minX + plotRect.width * progress
                path.move(to: CGPoint(x: x, y: plotRect.minY))
                path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
            }
        }
    }

    private func baselinePath(in plotRect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
            path.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
        }
    }

    private func barsPath(points: [CGPoint], plotRect: CGRect) -> Path {
        Path { path in
            for point in points {
                path.move(to: CGPoint(x: point.x, y: plotRect.maxY))
                path.addLine(to: point)
            }
        }
    }

    private func areaPath(points: [CGPoint], plotRect: CGRect) -> Path {
        Path { path in
            guard points.count >= 2, let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: plotRect.maxY))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.addLine(to: CGPoint(x: last.x, y: plotRect.maxY))
            path.closeSubpath()
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func failuresPath(in plotRect: CGRect, metrics: PathLatencyChartMetrics) -> Path {
        Path { path in
            guard let timeRange = metrics.timeRange else { return }
            for record in metrics.failureRecords {
                let x = xPosition(for: record.timestamp, in: plotRect, timeRange: timeRange)
                path.move(to: CGPoint(x: x, y: plotRect.minY))
                path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
            }
        }
    }

    private func axisOverlay(plotRect: CGRect, metrics: PathLatencyChartMetrics) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0 ... 3, id: \.self) { index in
                let progress = CGFloat(index) / 3
                let value = Int(round(Double(metrics.yAxisMax) * Double(progress)))
                Text("\(value)ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .position(x: leftAxisWidth / 2, y: plotRect.maxY - plotRect.height * progress)
            }

            if let timeRange = metrics.timeRange {
                ForEach(0 ... 3, id: \.self) { index in
                    let progress = Double(index) / 3.0
                    let date = timeRange.lowerBound.addingTimeInterval(timeRange.upperBound.timeIntervalSince(timeRange.lowerBound) * progress)
                    Text(Self.axisDateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .position(x: plotRect.minX + plotRect.width * CGFloat(progress), y: plotRect.maxY + 18)
                }
            }
        }
    }

    private func xPosition(for date: Date, in plotRect: CGRect, timeRange: ClosedRange<Date>) -> CGFloat {
        let duration = max(timeRange.upperBound.timeIntervalSince(timeRange.lowerBound), 1)
        let progress = date.timeIntervalSince(timeRange.lowerBound) / duration
        return plotRect.minX + plotRect.width * CGFloat(min(1, max(0, progress)))
    }

    private func yPosition(for latency: Int, in plotRect: CGRect, yAxisMax: Int) -> CGFloat {
        let progress = CGFloat(min(1, max(0, Double(latency) / Double(max(yAxisMax, 1)))))
        return plotRect.maxY - plotRect.height * progress
    }
}

@available(macOS 13.0, *)
private struct ModernLatencyChart: View {
    let records: [ProbeRecord]
    let color: Color
    let showsDenseBars: Bool
    let showsArea: Bool
    @State private var selectedDate: Date?

    var body: some View {
        if #available(macOS 14.0, *) {
            baseChart
                .chartXSelection(value: $selectedDate)
        } else {
            baseChart
        }
    }

    private var baseChart: some View {
        Chart {
            ForEach(records) { point in
                if let latency = point.latencyMs, point.success {
                    if showsArea {
                        AreaMark(
                            x: .value("时间", point.timestamp),
                            y: .value("延迟", latency)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.30), color.opacity(0.035)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    LineMark(
                        x: .value("时间", point.timestamp),
                        y: .value("延迟", latency)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

                    if showsDenseBars {
                        BarMark(
                            x: .value("时间", point.timestamp),
                            y: .value("延迟", latency)
                        )
                        .foregroundStyle(color.opacity(0.34))
                    }
                } else {
                    RuleMark(x: .value("失败时间", point.timestamp))
                        .foregroundStyle(.red.opacity(0.35))
                }
            }

            if let selectedDate {
                RuleMark(x: .value("选择时间", selectedDate))
                    .foregroundStyle(color.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .transaction { transaction in
            transaction.animation = nil
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let latency = value.as(Int.self) {
                        Text("\(latency)ms")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month().day().hour().minute())
                    }
                }
            }
        }
    }
}

@available(macOS 13.0, *)
private struct ModernMenuLatencySparkline: View {
    let records: [ProbeRecord]
    let color: Color

    var body: some View {
        Chart {
            ForEach(records) { point in
                if let latency = point.latencyMs, point.success {
                    LineMark(
                        x: .value("时间", point.timestamp),
                        y: .value("延迟", latency)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

                    BarMark(
                        x: .value("时间", point.timestamp),
                        y: .value("延迟", latency)
                    )
                    .foregroundStyle(color.opacity(0.38))
                } else {
                    RuleMark(x: .value("失败时间", point.timestamp))
                        .foregroundStyle(.red.opacity(0.45))
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: true))
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

@available(macOS 13.0, *)
private struct ModernMultiLatencyChart: View {
    let records: [ProbeRecord]
    let proxyNames: [String]
    @State private var selectedDate: Date?

    private func color(for proxyName: String) -> Color {
        let palette = AccentColorOption.all.map(\.color)
        guard let index = proxyNames.firstIndex(of: proxyName), !palette.isEmpty else {
            return .purple
        }
        return palette[index % palette.count]
    }

    var body: some View {
        if #available(macOS 14.0, *) {
            baseChart
                .chartXSelection(value: $selectedDate)
        } else {
            baseChart
        }
    }

    private var baseChart: some View {
        Chart {
            ForEach(records) { point in
                if let latency = point.latencyMs, point.success {
                    LineMark(
                        x: .value("时间", point.timestamp),
                        y: .value("延迟", latency)
                    )
                    .foregroundStyle(by: .value("节点", point.proxyName))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                } else {
                    RuleMark(x: .value("失败时间", point.timestamp))
                        .foregroundStyle(.red.opacity(0.28))
                }
            }

            if let selectedDate {
                RuleMark(x: .value("选择时间", selectedDate))
                    .foregroundStyle(.secondary.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartForegroundStyleScale(
            domain: proxyNames,
            range: proxyNames.map { color(for: $0) }
        )
        .chartYScale(domain: .automatic(includesZero: true))
        .transaction { transaction in
            transaction.animation = nil
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let latency = value.as(Int.self) {
                        Text("\(latency)ms")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month().day().hour().minute())
                    }
                }
            }
        }
    }
}

@available(macOS 12.0, *)
struct StatCard: View {
    let title: String
    let value: String
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            Text(title)
                .font((compact ? Font.footnote : Font.subheadline).weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: compact ? 20 : 23, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 14 : 18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .gentleAppear()
    }
}

@available(macOS 12.0, *)
struct MenuBarPanel: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var panelAnimation: Animation? {
        reduceMotion ? nil : MotionTokens.soft
    }

    var body: some View {
        let menuProxyName = model.monitoredProxyNames.first ?? "DIRECT"
        let stats = model.stats(for: menuProxyName)
        let records = model.chartData(hours: 4, proxy: menuProxyName, maxTotalPoints: 180, minimumPointsPerSeries: 180)

        VStack(alignment: .leading, spacing: 10) {
            Text(menuProxyName)
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(stats.lastLatency.map { "\($0)" } ?? "--")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("ms")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(model.isRunning ? .green : .secondary)
                    .frame(width: 8, height: 8)
            }

            MenuLatencySparkline(records: records, color: model.accentColor)
                .frame(height: 86)
                .overlay {
                    if records.isEmpty {
                        Text(model.t("等待数据"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            HStack {
                Text(model.monitoringStatusText)
                Spacer()
                Text("\(model.monitoredProxyNames.count) \(model.t("节点")) · 4h \(model.t("趋势"))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            Button(model.t("立即探测")) {
                Task { await model.runProbe() }
            }
            Button(model.isRunning ? model.t("停止监控") : model.t("开始监控")) {
                model.isRunning ? model.stopMonitoring() : model.startMonitoring()
            }
        }
        .padding(14)
        .frame(width: 320)
        .compatibleTint(model.accentColor)
        .animation(panelAnimation, value: model.recordsRevision)
    }
}

@available(macOS 12.0, *)
struct StatusBarBridge: NSViewRepresentable {
    @ObservedObject var model: AppModel

    func makeNSView(context: Context) -> NSView {
        StatusBarController.shared.configure(model: model)
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        StatusBarController.shared.configure(model: model)
        StatusBarController.shared.updateTitle()
    }
}

@available(macOS 12.0, *)
struct MacOS12StatusBarBridge: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if #available(macOS 13.0, *) {
            EmptyView()
        } else {
            StatusBarBridge(model: model)
        }
    }
}

@MainActor
@available(macOS 12.0, *)
final class StatusBarController: NSObject {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var model: AppModel?
    private var lastRenderedTitle = ""

    func configure(model: AppModel) {
        let modelChanged = self.model !== model
        self.model = model

        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "Latency Graph")
            item.button?.imagePosition = .imageLeading
            item.button?.target = self
            item.button?.action = #selector(togglePopover(_:))
            statusItem = item
        }

        if popover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.animates = true
            self.popover = popover
        }

        if modelChanged || popover?.contentViewController == nil {
            popover?.contentViewController = NSHostingController(
                rootView: MenuBarPanel()
                    .environmentObject(model)
            )
        }
        updateTitle()
    }

    func updateTitle() {
        guard let model, let button = statusItem?.button else { return }
        let latency = model.stats(for: model.monitoredProxyNames).lastLatency
        let title = latency.map { " \($0)ms" } ?? " --"
        guard title != lastRenderedTitle else { return }
        lastRenderedTitle = title
        button.title = title
    }

@objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var statusPopover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMainWindow()
        buildStatusItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    private func showMainWindow() {
        if window == nil {
            buildMainWindow()
            return
        }

        if window?.isMiniaturized == true {
            window?.deminiaturize(nil)
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildMainWindow() {
        let rootView = RootContentView()
            .environmentObject(model)

        let hostingController = NSHostingController(rootView: rootView)
        let usesIntegratedTitlebar = RuntimeFeaturePlan.current.usesSwiftUIAppLifecycle
        let styleMask: NSWindow.StyleMask = usesIntegratedTitlebar
            ? [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            : [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 820),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = "Latency Graph for ClashX Meta"
        window.titleVisibility = usesIntegratedTitlebar ? .hidden : .visible
        window.titlebarAppearsTransparent = usesIntegratedTitlebar
        if #available(macOS 11.0, *) {
            window.toolbarStyle = .unified
        }
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "Latency Graph")
                button.imagePosition = .imageLeading
            }
            button.title = " --"
            button.target = self
            button.action = #selector(toggleStatusPopover(_:))
        }
        statusItem = item

        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: RootContentView.compactMenu(model: model)
        )
        statusPopover = popover
    }

    @objc private func toggleStatusPopover(_ sender: NSStatusBarButton) {
        guard let popover = statusPopover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            refreshStatusTitle()
        }
    }

    private func refreshStatusTitle() {
        let latency = model.stats(for: model.monitoredProxyNames).lastLatency
        statusItem?.button?.title = latency.map { " \($0)ms" } ?? " --"
    }
}

struct RootContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if #available(macOS 12.0, *) {
            ModernContentView()
        } else {
            LegacyContentView()
        }
    }

    static func compactMenu(model: AppModel) -> some View {
        Group {
            if #available(macOS 12.0, *) {
                MenuBarPanel()
                    .environmentObject(model)
            } else {
                LegacyMenuPanel()
                    .environmentObject(model)
            }
        }
    }
}

@available(macOS 15.0, *)
struct SequoiaEnhancedContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var entranceAnimation: Animation? {
        model.runtimeProfile.pageAnimation(reduceMotion: reduceMotion)
    }

    var body: some View {
        ModernContentView()
            .animation(entranceAnimation, value: model.accentColorID)
    }
}

struct LegacyContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedHours: Double = 24

    private var versionedMotionProfile: VersionedMotionProfile {
        VersionedMotionProfile(runtimeProfile: model.runtimeProfile, intensity: model.motionIntensity)
    }

    private var selectedRecords: [ProbeRecord] {
        model.chartData(hours: selectedHours, proxies: model.monitoredProxyNames, maxTotalPoints: 420, minimumPointsPerSeries: 160)
    }

    var body: some View {
        HStack(spacing: 0) {
            legacySidebar
                .frame(width: 252)
                .background(legacySidebarBackground)
                .legacyAppear(index: 0, distance: 0)

            VStack(alignment: .leading, spacing: 16) {
                Text(model.t("节点监控"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .fontWeight(.bold)
                    .legacyAppear(index: 1)

                LegacyStatsStrip(stats: model.stats(for: model.monitoredProxyNames), model: model)
                    .legacyAppear(index: 2)

                HStack {
                    Text(model.t("延迟曲线"))
                        .font(.headline)
                    Spacer()
                    Picker(model.t("时间范围"), selection: $selectedHours) {
                        Text("1h").tag(1.0)
                        Text("4h").tag(4.0)
                        Text("12h").tag(12.0)
                        Text("24h").tag(24.0)
                        Text("7d").tag(168.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 360)
                }
                .legacyAppear(index: 3)

                LegacyLatencyChart(records: selectedRecords, color: model.accentColor)
                    .id(selectedRecords.count)
                    .frame(height: 320)
                    .padding(12)
                    .legacy15Panel(cornerRadius: 16, accentColor: model.accentColor)
                    .legacyInteractiveCard()
                    .legacyAppear(index: 4, distance: 14)

                LegacyRecordsList(records: model.recentRecords(limit: 60), model: model)
                    .legacy15Panel(cornerRadius: 16, accentColor: model.accentColor)
                    .legacyAppear(index: 5, distance: 14)
            }
            .padding(20)
            .background(legacyDetailBackground)
        }
        .frame(minWidth: 980, minHeight: 700)
        .background(legacyWindowBackground)
        .legacyAppear(index: 0, distance: 8)
        .legacyVersionedStartupMotion(profile: versionedMotionProfile)
    }

    private var legacySidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                legacySidebarSection(model.t("Language")) {
                    Picker("", selection: $model.languageCode) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                legacySidebarSection(model.t("动态效果")) {
                    Picker("", selection: $model.motionIntensityID) {
                        Text(model.t("增强")).tag(MotionIntensity.enhanced.rawValue)
                        Text(model.t("减弱")).tag(MotionIntensity.reduced.rawValue)
                        Text(model.t("无动画")).tag(MotionIntensity.none.rawValue)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                legacySidebarSection(model.t("主要颜色")) {
                    LegacyAccentColorStrip(model: model)
                }

                legacySidebarSection(model.t("控制")) {
                    Button(model.isRunning ? model.t("停止监控") : model.t("开始监控")) {
                        model.isRunning ? model.stopMonitoring() : model.startMonitoring()
                    }
                    .buttonStyle(Legacy15ControlButtonStyle(isProminent: true, accentColor: model.accentColor))

                    Button(model.t("立即探测")) {
                        Task { await model.runProbe() }
                    }
                    .buttonStyle(Legacy15ControlButtonStyle(isProminent: false, accentColor: model.accentColor))

                    Button(model.t("刷新代理列表")) {
                        Task { await model.refreshProxyCatalog() }
                    }
                    .buttonStyle(Legacy15ControlButtonStyle(isProminent: false, accentColor: model.accentColor))

                    Button(model.t("删除历史数据")) {
                        model.clearHistory()
                    }
                    .buttonStyle(Legacy15ControlButtonStyle(isProminent: false, accentColor: model.accentColor))
                }

                legacySidebarSection(model.t("设置")) {
                    LegacyFieldLabel(model.t("Controller URL"))
                    TextField(model.t("Controller URL"), text: $model.controllerURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    LegacyFieldLabel(model.t("探测目标"))
                    TextField(model.t("探测目标"), text: $model.targetURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Picker(model.t("数据点间隔"), selection: $model.probeIntervalMs) {
                        Text("5000").tag(5000)
                        Text("10000").tag(10000)
                        Text("30000").tag(30000)
                        Text("60000").tag(60000)
                        Text("120000").tag(120000)
                    }
                }

                legacySidebarSection(model.t("状态")) {
                    LegacyStatusLine(title: model.t("当前节点"), value: model.resolvedProxyName)
                    LegacyStatusLine(title: model.t("监控节点数"), value: "\(model.monitoredProxyNames.count)")
                    LegacyStatusLine(title: model.t("监控状态"), value: model.monitoringStatusText)
                }
            }
            .padding(14)
        }
    }

    private var legacyWindowBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(NSColor.windowBackgroundColor).opacity(0.98),
                Color(NSColor.controlBackgroundColor).opacity(0.88)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var legacySidebarBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(NSColor.controlBackgroundColor).opacity(0.88),
                Color(NSColor.windowBackgroundColor).opacity(0.72)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var legacyDetailBackground: some View {
        Color(NSColor.windowBackgroundColor).opacity(0.24)
    }

    private func legacySidebarSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(10)
            .legacy15Panel(cornerRadius: 12, accentColor: model.accentColor)
        }
    }
}

struct LegacyFieldLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

struct LegacyStatusLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
        }
        .font(.system(size: 12))
    }
}

struct LegacyAccentColorStrip: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 5) {
            ForEach(Array(AccentColorOption.all.chunked(into: 8).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 7) {
                    ForEach(row) { option in
                        Button {
                            model.accentColorID = option.id
                        } label: {
                            ZStack {
                                Capsule(style: .continuous)
                                    .fill(option.color)
                                    .frame(height: 14)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .strokeBorder(model.accentColorID == option.id ? Color.primary.opacity(0.9) : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(LegacyButtonMotionStyle())
                    }
                }
            }
        }
    }
}

struct LegacyStatsStrip: View {
    let stats: StatsSummary
    let model: AppModel

    var body: some View {
        HStack(spacing: 10) {
            LegacyStatCard(title: model.t("上次延迟"), value: stats.lastLatency.map { "\($0) ms" } ?? "--")
            LegacyStatCard(title: model.t("24h 平均延迟"), value: stats.avgLatency24h.map { String(format: "%.1f ms", $0) } ?? "--")
            LegacyStatCard(title: model.t("24h 最高延迟"), value: stats.maxLatency24h.map { "\($0) ms" } ?? "--")
            LegacyStatCard(title: model.t("24h 丢包率"), value: String(format: "%.1f%%", stats.packetLoss24h * 100))
            LegacyStatCard(title: model.t("24h 可用率"), value: String(format: "%.1f%%", stats.availability24h * 100))
        }
    }
}

struct LegacyStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .legacy15Panel(cornerRadius: 14, accentColor: .clear)
        .legacyInteractiveCard()
    }
}

struct LegacyLatencyChart: View {
    let records: [ProbeRecord]
    let color: Color
    @State private var reveal: CGFloat = 0

    private var successes: [ProbeRecord] {
        records.filter { $0.success && $0.latencyMs != nil }.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let rect = geometry.frame(in: .local).insetBy(dx: 40, dy: 24)
                    for index in 0 ... 3 {
                        let y = rect.maxY - rect.height * CGFloat(index) / 3
                        path.move(to: CGPoint(x: rect.minX, y: y))
                        path.addLine(to: CGPoint(x: rect.maxX, y: y))
                    }
                }
                .stroke(Color.secondary.opacity(0.22), lineWidth: 1)

                Path { path in
                    let rect = geometry.frame(in: .local).insetBy(dx: 40, dy: 24)
                    guard let first = successes.first,
                          let last = successes.last
                    else { return }
                    let maxLatency = max(1, successes.compactMap(\.latencyMs).max() ?? 1)
                    let duration = max(last.timestamp.timeIntervalSince(first.timestamp), 1)
                    for (index, record) in successes.enumerated() {
                        guard let latency = record.latencyMs else { continue }
                        let x = rect.minX + rect.width * CGFloat(record.timestamp.timeIntervalSince(first.timestamp) / duration)
                        let y = rect.maxY - rect.height * CGFloat(Double(latency) / Double(maxLatency))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: reveal)
                .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                if successes.isEmpty {
                    Text(modelTextUnavailable)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            reveal = 0
            withAnimation(MotionTokens.legacyChart) {
                reveal = 1
            }
        }
    }

    private var modelTextUnavailable: String {
        "No latency data"
    }
}

struct LegacyRecordsList: View {
    let records: [ProbeRecord]
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.t("最近记录"))
                .font(.headline)
            VStack(spacing: 0) {
                HStack {
                    Text(model.t("时间"))
                        .frame(width: 92, alignment: .leading)
                    Text(model.t("节点"))
                        .frame(width: 190, alignment: .leading)
                    Text(model.t("结果"))
                        .frame(width: 78, alignment: .leading)
                    Spacer()
                    Text(model.t("延迟"))
                        .frame(width: 72, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.58))

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(records) { record in
                            LegacyRecordRow(record: record, model: model)
                            Divider()
                                .opacity(0.42)
                        }
                        if records.isEmpty {
                            Text("--")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                    }
                }
                .frame(minHeight: 160, maxHeight: 220)
            }
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.09), lineWidth: 1)
            )
        }
        .padding(12)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

struct LegacyRecordRow: View {
    let record: ProbeRecord
    let model: AppModel

    var body: some View {
        HStack {
            Text(Self.timeFormatter.string(from: record.timestamp))
                .frame(width: 92, alignment: .leading)
            Text(record.proxyName)
                .lineLimit(1)
                .frame(width: 190, alignment: .leading)
            Text(record.success ? model.t("成功") : model.t("失败"))
                .foregroundColor(record.success ? .green : .red)
                .frame(width: 78, alignment: .leading)
            Spacer()
            Text(record.latencyMs.map { "\($0) ms" } ?? "--")
                .frame(width: 72, alignment: .trailing)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.34))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

struct LegacyMenuPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.monitoredProxyNames.first ?? "DIRECT")
                .font(.headline)
            Text(model.stats(for: model.monitoredProxyNames).lastLatency.map { "\($0) ms" } ?? "--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Button(model.t("立即探测")) {
                Task { await model.runProbe() }
            }
            .buttonStyle(LegacyButtonMotionStyle())
            Button(model.isRunning ? model.t("停止监控") : model.t("开始监控")) {
                model.isRunning ? model.stopMonitoring() : model.startMonitoring()
            }
            .buttonStyle(LegacyButtonMotionStyle())
        }
        .padding(14)
        .frame(width: 260)
    }
}
