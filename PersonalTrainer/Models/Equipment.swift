import SwiftUI

/// Equipment / station types, each with a blueprint line-art icon in the asset
/// catalog (template-rendered, so it tints with the foreground color).
enum Equipment: String, CaseIterable, Identifiable, Codable {
    case barbell
    case squatRack
    case dumbbell
    case kettlebell
    case bench
    case cable
    case machine
    case bodyweight
    case treadmill

    var id: String { rawValue }

    var name: String {
        switch self {
        case .barbell: return "Barbell"
        case .squatRack: return "Squat Rack"
        case .dumbbell: return "Dumbbell"
        case .kettlebell: return "Kettlebell"
        case .bench: return "Bench"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .treadmill: return "Cardio"
        }
    }

    /// Asset-catalog image name for the blueprint icon.
    var asset: String {
        switch self {
        case .barbell: return "eq_barbell"
        case .squatRack: return "eq_squatrack"
        case .dumbbell: return "eq_dumbbell"
        case .kettlebell: return "eq_kettlebell"
        case .bench: return "eq_bench"
        case .cable: return "eq_cable"
        case .machine: return "eq_machine"
        case .bodyweight: return "eq_bodyweight"
        case .treadmill: return "eq_treadmill"
        }
    }

    /// The blueprint icon as a template image.
    var image: Image {
        Image(asset).renderingMode(.template)
    }

    /// Stable display order (mirrors `allCases`).
    var sortOrder: Int {
        Equipment.allCases.firstIndex(of: self) ?? 0
    }
}
