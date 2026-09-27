import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var store: UsageStore

    var body: some View {
        Form {
            Section("Расположение") {
                Picker("Край экрана", selection: $preferences.edge) {
                    ForEach(NotchEdge.allCases) { Text($0.title).tag($0) }
                }
                Toggle("На всех дисплеях", isOn: $preferences.allDisplays)
                Toggle("Всегда развёрнут", isOn: $preferences.alwaysExpanded)
                Slider(value: $preferences.scale, in: 0.8...1.25, step: 0.05) {
                    Text("Масштаб")
                }
            }
            Section("Данные") {
                Toggle("Демонстрационные данные", isOn: $preferences.demo)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    LabeledContent("Состояние", value: store.message(at: context.date))
                }
                Text("Корпоративный источник лимитов пока не подключён. Приложение не обращается к сети, файлам других программ и не запускает команды.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}
