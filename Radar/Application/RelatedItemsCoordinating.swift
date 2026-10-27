/// The panel can request details from the live services or the local demonstration.
@MainActor
protocol RelatedItemsCoordinating: AnyObject {
    func selectionChanged()
    func refresh()
    func stop()
}
