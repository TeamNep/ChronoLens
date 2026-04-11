import Foundation
import UIKit

// MARK: - Vision API (Landmark Identification)

struct NVIDIAVisionService {
    private let apiKey = "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"
    private let endpoint = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!

    func identifyLandmark(imageData: Data) async throws -> (name: String, summary: String) {
        guard let uiImage = UIImage(data: imageData) else {
            throw ServiceError.invalidImage
        }

        let resized = resizeImage(uiImage, maxDimension: 800)
        guard let jpegData = resized.jpegData(compressionQuality: 0.6) else {
            throw ServiceError.invalidImage
        }

        let base64 = jpegData.base64EncodedString()
        let dataUrl = "data:image/jpeg;base64,\(base64)"

        let body: [String: Any] = [
            "model": "nvidia/nemotron-nano-12b-v2-vl",
            "messages": [
                ["role": "system", "content": "/no_think"],
                ["role": "user", "content": [
                    ["type": "text", "text": """
                    What landmark, building, or artwork is shown in this image? \
                    Identify it and respond in this exact format:
                    Name: [name of the place]
                    Summary: [2-3 sentence historical summary]
                    """],
                    ["type": "image_url", "image_url": ["url": dataUrl]]
                ] as [[String: Any]]]
            ] as [[String: Any]],
            "max_tokens": 4096,
            "temperature": 0.5,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "stream": false
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ServiceError.apiError(msg)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ServiceError.parseError
        }

        let cleaned = content
            .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return parseLandmarkResponse(cleaned)
    }

    private func parseLandmarkResponse(_ text: String) -> (name: String, summary: String) {
        var name = ""
        var summary = ""

        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("name:") {
                name = trimmed
                    .replacingOccurrences(of: "(?i)^name:\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "*#"))
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().hasPrefix("summary:") {
                summary = trimmed
                    .replacingOccurrences(of: "(?i)^summary:\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // If structured parsing failed, use heuristics
        if name.isEmpty {
            name = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Place"
            if name.count > 100 { name = String(name.prefix(100)) }
        }
        if summary.isEmpty {
            let remaining = lines.dropFirst().joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            summary = remaining.isEmpty ? text : remaining
        }

        return (name, summary)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Text API (Q&A Chat)

struct NVIDIATextService {
    private let apiKey = "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"
    private let endpoint = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!

    func askQuestion(
        about placeName: String,
        summary: String,
        conversationHistory: [(role: String, content: String)],
        question: String
    ) async throws -> String {
        let systemPrompt = """
        You are a knowledgeable historian and cultural guide. \
        The user is asking about \(placeName). \
        Here is what we know: \(summary)

        Provide detailed, accurate, and engaging answers. \
        If you are not sure about something, say so. \
        Keep responses concise but informative (2-4 paragraphs max).
        """

        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        for turn in conversationHistory {
            messages.append(["role": turn.role, "content": turn.content])
        }
        messages.append(["role": "user", "content": question])

        let body: [String: Any] = [
            "model": "openai/gpt-oss-20b",
            "messages": messages,
            "temperature": 1,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "max_tokens": 4096,
            "stream": false,
            "reasoning_effort": "medium"
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ServiceError.apiError(msg)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ServiceError.parseError
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum ServiceError: LocalizedError {
    case invalidImage
    case apiError(String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .apiError(let msg): return "API error: \(msg)"
        case .parseError: return "Could not parse the API response."
        }
    }
}
