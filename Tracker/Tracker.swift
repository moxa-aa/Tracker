import UIKit

enum WeekDay: String, CaseIterable {
    case monday = "Понедельник"
    case tuesday = "Вторник"
    case wednesday = "Среда"
    case thursday = "Четверг"
    case friday = "Пятница"
    case saturday = "Суббота"
    case sunday = "Воскресенье"
    
    var shortName: String {
        return localizedShortName
    }
    
    var localizedName: String {
        switch self {
        case .monday: return L10n.weekdayMonday
        case .tuesday: return L10n.weekdayTuesday
        case .wednesday: return L10n.weekdayWednesday
        case .thursday: return L10n.weekdayThursday
        case .friday: return L10n.weekdayFriday
        case .saturday: return L10n.weekdaySaturday
        case .sunday: return L10n.weekdaySunday
        }
    }
    
    var localizedShortName: String {
        switch self {
        case .monday: return L10n.weekdayShortMonday
        case .tuesday: return L10n.weekdayShortTuesday
        case .wednesday: return L10n.weekdayShortWednesday
        case .thursday: return L10n.weekdayShortThursday
        case .friday: return L10n.weekdayShortFriday
        case .saturday: return L10n.weekdayShortSaturday
        case .sunday: return L10n.weekdayShortSunday
        }
    }
}

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: Set<WeekDay>
    let isPinned: Bool
}
