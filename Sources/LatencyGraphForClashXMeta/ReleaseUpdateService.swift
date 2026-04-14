import Foundation

struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    var displayVersion: String {
        tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }

    func isNewer(than version: String) -> Bool {
        VersionNumber(displayVersion) > VersionNumber(version)
    }
}

struct GitHubReleaseUpdateService {
    let owner: String
    let repo: String

    func latestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest") else {
            throw AppError.custom("GitHub Release URL 无效")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw AppError.custom("GitHub Release 响应无效")
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}

private struct VersionNumber: Comparable {
    let parts: [Int]

    init(_ rawValue: String) {
        parts = rawValue
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split(separator: ".")
            .map { Int($0.filter(\.isNumber)) ?? 0 }
    }

    static func < (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        let maxCount = max(lhs.parts.count, rhs.parts.count)
        for index in 0 ..< maxCount {
            let left = index < lhs.parts.count ? lhs.parts[index] : 0
            let right = index < rhs.parts.count ? rhs.parts[index] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }
}
