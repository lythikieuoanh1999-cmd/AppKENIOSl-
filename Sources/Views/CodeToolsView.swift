import SwiftUI
import UIKit

struct CodeToolsView: View {
    @EnvironmentObject var store: AppStore
    @State private var seg = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $seg) {
                    Text("Chạy Python").tag(0)
                    Text("AI lập trình").tag(1)
                }
                .pickerStyle(.segmented).padding()
                if seg == 0 { RunPythonPane() } else { CodeAIPane() }
            }
            .navigationTitle("Lập trình")
        }
    }
}

// ======================== Chạy Python trên server ========================
struct RunPythonPane: View {
    @EnvironmentObject var store: AppStore
    @State private var code = "print(\"Xin chào KENIOS!\")"
    @State private var stdin = ""
    @State private var result: CodeRunResult?
    @State private var running = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Code Python").font(.subheadline.bold())
                TextEditor(text: $code)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 160)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text("Stdin (tuỳ chọn)").font(.subheadline.bold())
                TextField("Dữ liệu nhập cho input()...", text: $stdin, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await run() }
                } label: {
                    HStack {
                        if running { ProgressView().tint(.white).padding(.trailing, 4) }
                        Text("Chạy code").bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Theme.accent).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(running || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let result {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Kết quả").font(.subheadline.bold())
                            Spacer()
                            Text("returncode: \(result.returncode)")
                                .font(.caption).foregroundStyle(result.returncode == 0 ? .green : .red)
                        }
                        if !result.stdout.isEmpty {
                            Text("stdout").font(.caption).foregroundStyle(.secondary)
                            Text(result.stdout)
                                .font(.system(.footnote, design: .monospaced))
                                .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                        if !result.stderr.isEmpty {
                            Text("stderr").font(.caption).foregroundStyle(.secondary)
                            Text(result.stderr)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.red)
                                .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                    }
                }

                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .padding()
        }
    }

    private func run() async {
        running = true; error = nil; result = nil
        do {
            result = try await store.api.runPython(code: code, stdin: stdin.isEmpty ? nil : stdin)
        } catch { self.error = error.localizedDescription }
        running = false
    }
}

// ======================== AI lập trình (review/debug/explain/...) ========================
struct CodeAIPane: View {
    @EnvironmentObject var store: AppStore

    @State private var code = ""
    @State private var language = "python"
    @State private var task = "review"
    @State private var targetLang = "JavaScript"
    @State private var provider = ""
    @State private var result: String?
    @State private var running = false
    @State private var error: String?

    private let tasks: [(String, String)] = [
        ("review", "Review code"),
        ("debug", "Debug / sửa lỗi"),
        ("explain", "Giải thích"),
        ("convert", "Chuyển ngôn ngữ"),
        ("test", "Viết unit test"),
        ("optimize", "Tối ưu hiệu năng"),
        ("document", "Viết docstring"),
        ("security", "Kiểm tra bảo mật"),
    ]
    private let languages = ["python", "javascript", "typescript", "swift", "kotlin",
                              "go", "rust", "c", "cpp", "java", "php", "html", "css", "sql", "shell"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dán code cần xử lý").font(.subheadline.bold())
                TextEditor(text: $code)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 160)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ngôn ngữ").font(.caption).foregroundStyle(.secondary)
                        Picker("Ngôn ngữ", selection: $language) {
                            ForEach(languages, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tác vụ").font(.caption).foregroundStyle(.secondary)
                        Picker("Tác vụ", selection: $task) {
                            ForEach(tasks, id: \.0) { Text($0.1).tag($0.0) }
                        }
                    }
                }

                if task == "convert" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chuyển sang").font(.caption).foregroundStyle(.secondary)
                        TextField("VD: JavaScript, Kotlin, Go...", text: $targetLang)
                            .padding(8).background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI sử dụng").font(.caption).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(store.providers.filter { ($0.code ?? false) }) { p in
                                Button { provider = p.id } label: {
                                    HStack(spacing: 6) {
                                        if provider == p.id { Image(systemName: "checkmark").font(.caption2) }
                                        Circle().fill(providerColor(p.id)).frame(width: 7, height: 7)
                                        Text(p.label.components(separatedBy: " · ").first ?? p.id)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(provider == p.id ? Theme.accent.opacity(0.25) : Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                                    .opacity(store.configuredKeys.contains(p.id) ? 1 : 0.4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Button {
                    Task { await run() }
                } label: {
                    HStack {
                        if running { ProgressView().tint(.white).padding(.trailing, 4) }
                        Text("Gửi cho AI").bold()
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Theme.accent).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(running || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || provider.isEmpty || !store.configuredKeys.contains(provider))

                if !store.configuredKeys.contains(provider) && !provider.isEmpty {
                    Text("Chưa có API key cho AI này. Vào Cài đặt → API Keys.")
                        .font(.caption).foregroundStyle(.orange)
                }

                if let result {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kết quả").font(.subheadline.bold())
                        Text(result)
                            .font(.system(.footnote, design: .monospaced))
                            .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .textSelection(.enabled)
                            .contextMenu {
                                Button { UIPasteboard.general.string = result } label: {
                                    Label("Sao chép", systemImage: "doc.on.doc")
                                }
                            }
                    }
                }

                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
            }
            .padding()
        }
        .onAppear {
            if provider.isEmpty {
                provider = store.configuredKeys.first(where: { id in
                    store.providers.first(where: { $0.id == id })?.code ?? false
                }) ?? store.providers.first(where: { $0.code ?? false })?.id ?? ""
            }
        }
    }

    private func run() async {
        running = true; error = nil; result = nil
        do {
            let r = try await store.api.codeAI(provider: provider, code: code, language: language,
                                               task: task, targetLang: task == "convert" ? targetLang : nil)
            result = r.result
        } catch { self.error = error.localizedDescription }
        running = false
    }
}
