import UIKit

public enum AgentLabel {
    private static let known: [String: (label: String, avatar: String)] = [
        "claude-code": ("Claude Code", "AgentClaude"),
        "claude": ("Claude", "AgentClaude"),
        "anthropic": ("Claude", "AgentClaude"),
        "codex": ("Codex", "AgentCodex"),
        "openai": ("OpenAI", "AgentOpenAI"),
        "chatgpt": ("ChatGPT", "AgentOpenAI"),
        "cursor": ("Cursor", "AgentCursor"),
        "copilot": ("Copilot", "AgentCopilot"),
        "github-copilot": ("Copilot", "AgentCopilot"),
        "gemini": ("Gemini", "AgentGemini"),
        "gemini-cli": ("Gemini CLI", "AgentGemini"),
        "jules": ("Jules", "AgentGemini"),
        "windsurf": ("Windsurf", "AgentWindsurf"),
        "zed": ("Zed", "AgentZed"),
        "replit": ("Replit", "AgentReplit"),
        "warp": ("Warp", "AgentWarp"),
        "v0": ("v0", "AgentV0"),
        "vercel": ("Vercel", "AgentV0"),
        "junie": ("Junie", "AgentJunie"),
        "jetbrains": ("JetBrains AI", "AgentJunie"),
        "mistral": ("Mistral", "AgentMistral"),
        "vibe": ("Mistral Vibe", "AgentMistral"),
        "deepseek": ("DeepSeek", "AgentDeepSeek"),
        "grok": ("Grok", "AgentGrok"),
        "cline": ("Cline", "AgentCline"),
        "roo": ("Roo Code", "AgentRoo"),
        "roo-code": ("Roo Code", "AgentRoo"),
        "kilo": ("Kilo Code", "AgentKilo"),
        "kilo-code": ("Kilo Code", "AgentKilo"),
        "opencode": ("OpenCode", "AgentOpenCode"),
        "qwen": ("Qwen", "AgentQwen"),
        "qwen-code": ("Qwen Code", "AgentQwen"),
        "perplexity": ("Perplexity", "AgentPerplexity"),
        "huggingface": ("Hugging Face", "AgentHuggingFace"),
        "ollama": ("Ollama", "AgentOllama"),
        "amp": ("Amp", "AgentAmp"),
        "trae": ("Trae", "AgentTrae"),
    ]

    private static let monogramColors: [UIColor] = [
        UIColor(red: 0.30, green: 0.36, blue: 0.96, alpha: 1),
        UIColor(red: 0.85, green: 0.40, blue: 0.27, alpha: 1),
        UIColor(red: 0.09, green: 0.60, blue: 0.53, alpha: 1),
        UIColor(red: 0.55, green: 0.36, blue: 0.87, alpha: 1),
        UIColor(red: 0.90, green: 0.48, blue: 0.13, alpha: 1),
        UIColor(red: 0.20, green: 0.47, blue: 0.86, alpha: 1),
    ]

    public static func resolve(_ agent: String) -> String {
        if let entry = known[normalize(agent)] { return entry.label }
        return agent
            .split(whereSeparator: { $0 == "-" || $0 == "_" || $0 == " " })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    public static func avatar(for agent: String) -> String? {
        known[normalize(agent)]?.avatar
    }

    public static func image(for agent: String) -> UIImage? {
        if let avatar = avatar(for: agent), let bundled = UIImage(named: avatar) { return bundled }
        return monogram(for: agent)
    }

    private static func monogram(for agent: String) -> UIImage? {
        let label = resolve(agent)
        guard let first = label.first else { return nil }
        let letter = String(first).uppercased()
        let color = monogramColors[Int(stableHash(label) % UInt64(monogramColors.count))]
        let size = CGSize(width: 256, height: 256)

        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 58).fill()
            let font = UIFont.systemFont(ofSize: 132, weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
            let bounds = (letter as NSString).size(withAttributes: attributes)
            (letter as NSString).draw(
                at: CGPoint(x: (size.width - bounds.width) / 2, y: (size.height - bounds.height) / 2),
                withAttributes: attributes
            )
            _ = context
        }
    }

    private static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.lowercased().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return hash
    }

    private static func normalize(_ agent: String) -> String {
        agent.lowercased().replacingOccurrences(of: "_", with: "-").replacingOccurrences(of: " ", with: "-")
    }
}
