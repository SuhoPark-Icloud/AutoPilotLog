import SwiftUI

enum AppTab: Equatable, Hashable, Identifiable {
    case map
    case issueList
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .map: return "지도"
        case .issueList: return "이슈 목록"
        case .settings: return "설정"
        }
    }

    var iconName: String {
        switch self {
        case .map: return "map"
        case .issueList: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}
