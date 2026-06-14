import SwiftUI

/// Lets the user grant Apple Music access and pick a workout playlist from their
/// library. The selection is remembered via @AppStorage in the session screen.
struct PlaylistPickerView: View {
    @ObservedObject var music: MusicService
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false
    var onSelect: (MusicService.PlaylistInfo) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if !music.authorized {
                    ContentUnavailableView {
                        Label("Apple Music Access", systemImage: "music.note")
                    } description: {
                        Text("Allow access to your music library to choose a workout playlist.")
                    } actions: {
                        Button("Allow Access") {
                            Task { isWorking = true; await music.requestAuthorization(); isWorking = false }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .foregroundStyle(Theme.blueprintDeep)
                    }
                } else if music.playlists.isEmpty {
                    ContentUnavailableView(
                        "No Playlists",
                        systemImage: "music.note.list",
                        description: Text("Create a playlist in the Apple Music app, then pull to refresh.")
                    )
                } else {
                    List(music.playlists) { playlist in
                        Button {
                            onSelect(playlist)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "music.note.list").foregroundStyle(Theme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                    Text("\(playlist.count) songs")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .tint(.primary)
                    }
                    .refreshable { music.loadPlaylists() }
                }
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .barLoadingOverlay(isWorking, label: "Loading your library…")
            .navigationTitle("Workout Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if music.authorized { music.loadPlaylists() } else { await music.requestAuthorization() }
            }
        }
    }
}
