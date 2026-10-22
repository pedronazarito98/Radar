enum PanelDismissalReason {
    case explicitToggle
    case escape
    case outsideClick
    case externalDestination
    case termination

    var restoresPreviousApplication: Bool {
        switch self {
        case .explicitToggle, .escape: true
        case .outsideClick, .externalDestination, .termination: false
        }
    }
}
