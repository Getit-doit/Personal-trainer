import SwiftUI
import MediaPlayer

/// Bridges to the system Apple Music player so the user can start a workout
/// playlist from their own library and control playback during a session.
///
/// Requires the `NSAppleMusicUsageDescription` Info.plist key (set via the
/// target's build settings) and an Apple Music / local library on the device.
/// The iOS Simulator has no music library, so playlists will be empty there.
@MainActor
final class MusicService: ObservableObject {

    struct PlaylistInfo: Identifiable, Hashable {
        let id: String          // persistentID rendered as a string
        let name: String
        let count: Int
    }

    @Published var authorized = false
    @Published var playlists: [PlaylistInfo] = []
    @Published var nowPlaying = ""
    @Published var isPlaying = false

    private let player = MPMusicPlayerController.systemMusicPlayer

    init() {
        authorized = MPMediaLibrary.authorizationStatus() == .authorized
        player.beginGeneratingPlaybackNotifications()

        let center = NotificationCenter.default
        center.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        center.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    func requestAuthorization() async {
        let status: MPMediaLibraryAuthorizationStatus = await withCheckedContinuation { cont in
            MPMediaLibrary.requestAuthorization { cont.resume(returning: $0) }
        }
        authorized = (status == .authorized)
        if authorized { loadPlaylists() }
    }

    func loadPlaylists() {
        guard authorized else { return }
        let collections = (MPMediaQuery.playlists().collections as? [MPMediaPlaylist]) ?? []
        playlists = collections.map { playlist in
            PlaylistInfo(
                id: String(playlist.persistentID),
                name: (playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String) ?? "Playlist",
                count: playlist.count
            )
        }
    }

    /// Queue and play a playlist by its persistent id.
    func play(playlistID: String) {
        guard authorized, let id = UInt64(playlistID) else { return }
        let query = MPMediaQuery.playlists()
        query.addFilterPredicate(
            MPMediaPropertyPredicate(
                value: NSNumber(value: id),
                forProperty: MPMediaPlaylistPropertyPersistentID
            )
        )
        guard let playlist = (query.collections as? [MPMediaPlaylist])?.first else { return }
        player.setQueue(with: playlist)
        player.play()
        refresh()
    }

    func togglePlayPause() {
        if player.playbackState == .playing { player.pause() } else { player.play() }
        refresh()
    }

    func skip() {
        player.skipToNextItem()
        refresh()
    }

    private func refresh() {
        isPlaying = (player.playbackState == .playing)
        nowPlaying = player.nowPlayingItem?.title ?? ""
    }
}
