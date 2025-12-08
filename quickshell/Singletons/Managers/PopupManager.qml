pragma Singleton
import QtQuick

QtObject {
    id: popupManager

    property list<QtObject> popups

    function register(popup) {
        if (popups.indexOf(popup) === -1)
            popups.push(popup) // observable now
    }

    function unregister(popup) {
        var i = popups.indexOf(popup)
        if (i !== -1)
            popups.splice(i, 1)
    }

    function closeAll() {
        for (let p of popups)
            p.visible = false
    }

    function hasOpenPopups() {
        return popups.some(p => p.visible)
    }

    function isPopUpOpen(popup) {
        return popups.indexOf(popup) !== -1
    }

    function toggle(popup) {
        if (!popup) return
        const shouldOpen = !popup.visible
        closeAll()
        popup.visible = shouldOpen
    }
}
