import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1024
    height: 600
    title: catalog.isOpened ? (catalog.fileName + ' - ' + Qt.application.name) : Qt.application.name
    color: Appearance.baseColor()

    property bool forceClosing: false
    property var recentFolder: openCatalogDialog.shortcuts.documents

    Settings {
        category: "MainWindow"
        property alias windowX: mainWindow.x
        property alias windowY: mainWindow.y
        property alias windowWidth: mainWindow.width
        property alias windowHeight: mainWindow.height
        property alias openedMemosViewWidth: openedMemosView.width
        property alias openedMemosViewVisible: showOpenedMemosViewMenuItem.checked
        property alias catalogViewWidth: catalogView.width
        property alias catalogViewVisible: showCatalogViewMenuItem.checked
        property alias statusBarVisible: showStatusBarMenuItem.checked
    }

    Settings {
        category: "State"
        property alias recentFolder: mainWindow.recentFolder
    }

    CatalogHandler {
        id: catalog

        onMemoCreated: {
            controller.openMemo(memoId)

            var page = memoPagesView.currentMemoPage
            if (page && page.memoId == memoId && !page.editMemoMode)
                page.beginEditing()
        }
    }

    MainController {
        id: controller
        catalog: catalog
        isMemoModified: memoPagesView.isMemoModified
        getModifiedMemos: memoPagesView.getModifiedMemos
        saveMemo: memoPagesView.saveMemo
    }

    Component.onCompleted: {
        // We can't restore visibility of these components automatically
        // because they are on a splitter and it restores their visibility
        // after its panels are restored. So we store action check state instead
        // and use it for setting visibilty of splitter subcomponents at the very end.
        catalogView.visible = showCatalogViewMenuItem.checked
        openedMemosView.visible = showOpenedMemosViewMenuItem.checked
        statusBar.visible = showStatusBarMenuItem.checked

        catalog.loadSettings()

        memoWordWrapMenuItem.checked = catalog.memoWordWrap

        openCatalogDialog.folder = mainWindow.recentFolder
        newCatalogDialog.folder = mainWindow.recentFolder

        if (catalog.recentFile)
            operations.loadCatalogFile(catalog.recentFile)
    }

    onClosing: {
        if (!forceClosing) {
            close.accepted = false
            catalog.saveSettings()
            operations.closeCatalog(function() {
                forceClosing = true
                mainWindow.close()
            })
        }
    }

    Item {
        id: operations

        function createNewCatalog(fileUrl) {
            closeCatalog(function() {
                catalog.newCatalog(fileUrl)
            });
        }

        function loadCatalogFile(fileName) {
            if (!catalog.sameFile(fileName)) {
                closeCatalog(function() {
                    catalog.loadCatalogFile(fileName)
                    restoreSession()
                })
            }
        }

        function loadCatalogUrl(fileUrl) {
            if (!catalog.sameUrl(fileUrl)) {
                closeCatalog(function() {
                    catalog.loadCatalogUrl(fileUrl)
                    restoreSession()
                })
            }
        }

        function closeCatalog(onAccept) {
            if (!catalog.isOpened) {
                onAccept()
                return
            }
            storeSession()
            controller.closeAllMemos(function() {
                catalog.closeCatalog()
                onAccept()
            })
        }

        function restoreSession() {
            var session = catalog.getStoredSession()

            openedMemosView.setAllIdsStr(session.openedMemos)
            catalogView.setExpandedIdsStr(session.expandedFolders)

            var activeMemoId = session.activeMemo
            if (activeMemoId > 0)
                controller.openMemo(activeMemoId)
        }

        function storeSession() {
            catalog.storeSession({
                openedMemos: openedMemosView.getAllIdsStr(),
                activeMemo: openedMemosView.currentMemoId,
                expandedFolders: catalogView.getExpandedIdsStr()
            })
        }
    }

    Shortcut {
        sequence: "F2"
        onActivated: {
            if (memoPagesView.currentMemoPage && memoPagesView.currentMemoPage.editMemoMode)
                memoPagesView.currentMemoPage.toggleFocus()
        }
    }

    menuBar: MenuBar {
        id: mainMenu
        Menu {
            id: fileMenu
            title: qsTr("File")
            MenuItem {
                text: qsTr("New...")
                iconName: "document-new"
                shortcut: StandardKey.New
                onTriggered: newCatalogDialog.open()
            }
            MenuItem {
                text: qsTr("Open...")
                iconName: "document-open"
                shortcut: StandardKey.Open
                onTriggered: openCatalogDialog.open()
            }
            MenuItem {
                text: qsTr("Close")
                enabled: catalog.isOpened
                onTriggered: operations.closeCatalog()
            }
            Menu {
                id: mruFileMenu
                title: qsTr("&Recent Files")
                Instantiator {
                    model: catalog.recentFilesModel
                    MenuItem {
                        text: modelData
                        onTriggered: operations.loadCatalogFile(text)
                    }
                    onObjectAdded: mruFileMenu.insertItem(index, object)
                    onObjectRemoved: mruFileMenu.removeItem(object)
                }
                MenuSeparator {
                    visible: catalog.hasRecentFiles
                }
                MenuItem {
                    text: qsTr("&Delete Invalid Items ")
                    enabled: catalog.hasRecentFiles
                    onTriggered: catalog.deleteInvalidMruItems()
                }
                MenuItem {
                    text: qsTr("&Clear History")
                    enabled: catalog.hasRecentFiles
                    onTriggered: catalog.deleteAllMruItems()
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Exit")
                iconName: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        }
        Menu {
            // TODO: how to display edit actions shortcuts in the main menu?
            // They clash with built-in shortcuts of TextArea
            id: editMenu
            title: qsTr("Edit")
            MenuItem {
                text: qsTr("Undo")
                iconName: "edit-undo"
                //shortcut: StandardKey.Undo -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("undo" in activeFocusItem)
                         && (!("readOnly" in activeFocusItem) || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.undo()
            }
            MenuItem {
                text: qsTr("Redo")
                iconName: "edit-redo"
                //shortcut: StandardKey.Redo -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("redo" in activeFocusItem)
                         && (!("readOnly" in activeFocusItem) || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.redo()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Cut")
                iconName: "edit-cut"
                //shortcut: StandardKey.Cut -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("cut" in activeFocusItem)
                         && (!("readOnly" in activeFocusItem) || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.cut()
            }
            MenuItem {
                text: qsTr("Copy")
                iconName: "edit-copy"
                //shortcut: StandardKey.Copy -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("copy" in activeFocusItem)
                onTriggered: activeFocusItem.copy()
            }
            MenuItem {
                text: qsTr("Paste")
                iconName: "edit-paste"
                //shortcut: StandardKey.Paste -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("paste" in activeFocusItem)
                         && (!activeFocusItem["readOnly"] || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.paste()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Select All")
                iconName: "edit-select-all"
                //shortcut: StandardKey.SelectAll -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("selectAll" in activeFocusItem)
                onTriggered: activeFocusItem.selectAll()
            }
        }
        Menu {
            id: viewMenu
            title: qsTr("View")
            MenuItem {
                id: showOpenedMemosViewMenuItem
                text: qsTr("Opened Memos Panel")
                checkable: true
                checked: true
                onToggled: openedMemosView.visible = checked
            }
            MenuItem {
                id: showCatalogViewMenuItem
                text: qsTr("Catalog Panel")
                checkable: true
                checked: true
                onToggled: catalogView.visible = checked
            }
            MenuItem {
                id: showStatusBarMenuItem
                text: qsTr("Status Bar")
                checkable: true
                checked: true
                onToggled: statusBar.visible = checked
            }
        }
        Menu {
            id: catalogMenu
            title: qsTr("Catalog")
            MenuItem {
                text: qsTr("New Root Folder...")
                enabled: catalog.isOpened
                onTriggered: controller.createFolder(0)
            }
            MenuItem {
                text: qsTr("New Folder...")
                enabled: catalogView.selectedFolderId > 0
                onTriggered: controller.createFolder(catalogView.selectedFolderId)
            }
            MenuItem {
                text: qsTr("Rename Folder...")
                enabled: catalogView.selectedFolderId > 0
                onTriggered: controller.renameFolder(catalogView.selectedFolderId)
            }
            MenuItem {
                text: qsTr("Delete Folder")
                enabled: catalogView.selectedFolderId > 0
                onTriggered: controller.deleteFolder(catalogView.selectedFolderId)
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Open Memo")
                enabled: catalogView.selectedMemoId > 0
                onTriggered: controller.openMemo(catalogView.selectedMemoId)
            }
            MenuItem {
                text: qsTr("New Memo")
                enabled: catalogView.selectedFolderId > 0
                onTriggered: catalog.createMemo(catalogView.selectedFolderId)
            }
            MenuItem {
                text: qsTr("Delete Memo")
                enabled: catalogView.selectedMemoId > 0
                onTriggered: controller.deleteMemo(catalogView.selectedMemoId)
            }
        }
        Menu {
            id: memoMenu
            title: qsTr("Memo")
            MenuItem {
                text: qsTr("Edit Memo")
                iconSource: "qrc:/toolbar/memo_edit"
                shortcut: "Return,Return"
                enabled: memoPagesView.currentMemoPage && !memoPagesView.currentMemoPage.editMemoMode
                onTriggered: memoPagesView.currentMemoPage.beginEditing()
            }
            MenuItem {
                text: qsTr("Save Memo")
                iconSource: "qrc:/toolbar/memo_save"
                shortcut: StandardKey.Save
                enabled: memoPagesView.currentMemoPage && memoPagesView.currentMemoPage.editMemoMode
                onTriggered: memoPagesView.currentMemoPage.saveChanges()
            }
            MenuItem {
                text: qsTr("Cancel Changes")
                iconSource: "qrc:/toolbar/memo_cancel"
                shortcut: "Esc,Esc"
                enabled: memoPagesView.currentMemoPage && memoPagesView.currentMemoPage.editMemoMode
                onTriggered: memoPagesView.currentMemoPage.cancelEditing()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Update Highlight")
                enabled: memoPagesView.currentMemoPage
                onTriggered: memoPagesView.currentMemoPage.updateHighlight()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Close Memo")
                iconSource: "qrc:/toolbar/memo_close"
                shortcut: StandardKey.Close
                enabled: openedMemosView.currentMemoId > 0
                onTriggered: controller.closeMemo(openedMemosView.currentMemoId)
            }
            MenuItem {
                text: qsTr("Close All Memos")
                enabled: openedMemosView.currentMemoId > 0
                onTriggered: controller.closeAllMemos()
            }
        }
        Menu {
            id: optionsMenu
            title: qsTr("Options")
            MenuItem {
                text: qsTr("Choose Memo Font...")
                onTriggered: {
                    memoFontDialog.font = catalog.memoFont
                    memoFontDialog.open()
                }
            }
            MenuItem {
                id: memoWordWrapMenuItem
                text: qsTr("Word Wrap")
                checkable: true
                onToggled: catalog.memoWordWrap = checked
            }
        }
    }

    statusBar: StatusBar {
        id: statusBar
        visible: !catalog.isOpened

        RowLayout {
            anchors.fill: parent
            anchors.margins: 2
            Row {
                visible: catalog.isOpened
                Label { text: qsTr("Memos: "); color: Appearance.textColorModest(); font.pointSize: Appearance.fontSizeDefaultUI() }
                Label { text: catalog.memoCount; font.pointSize: Appearance.fontSizeDefaultUI() }
            }
            Row {
                visible: catalog.isOpened
                leftPadding: 6
                Label { text: qsTr("Opened: "); color: Appearance.textColorModest(); font.pointSize: Appearance.fontSizeDefaultUI() }
                Label { text: memoPagesView.count; font.pointSize: Appearance.fontSizeDefaultUI() }
            }
            Row {
                leftPadding: 6
                Label { text: qsTr("Catalog: "); color: Appearance.textColorModest(); font.pointSize: Appearance.fontSizeDefaultUI() }
                Label { text: catalog.filePath || qsTr("(not selected)"); font.pointSize: Appearance.fontSizeDefaultUI() }
            }
            Item { Layout.fillWidth: true }
        }
    }

    SplitView {
        id: centralArea
        anchors.fill: parent
        orientation: Qt.Horizontal
        handleDelegate: Rectangle {
            width: 4
            color: styleData.pressed ? Appearance.selectionColor() : Appearance.baseColor()
        }

        OpenedMemosView {
            id: openedMemosView
            catalog: catalog
            controller: controller
            width: 255
            height: parent.height
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
        }

        MemoPagesView {
            id: memoPagesView
            catalog: catalog
            controller: controller
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.topMargin: 4
            Layout.leftMargin: openedMemosView.visible ? 0 : 4
            Layout.rightMargin: catalogView.visible ? 0 : 4
        }

        CatalogView {
            id: catalogView
            catalog: catalog
            controller: controller
            catalogModel: catalog.model
            width: 255
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
            Layout.rightMargin: 4
            Layout.bottomMargin: 4
            Layout.topMargin: 4
        }
    }

    Item {
        id: dialogs

        FileDialog {
            id: openCatalogDialog
            nameFilters: [qsTr("Procyon Memo Catalogs (*.enot)"), qsTr("All files (*.*)")]
            onAccepted: {
                mainWindow.recentFolder = folder
                operations.loadCatalogUrl(fileUrl)
            }
        }

        FileDialog {
            id: newCatalogDialog
            nameFilters: openCatalogDialog.nameFilters
            selectExisting: false
            onAccepted: {
                mainWindow.recentFolder = folder
                operations.createNewCatalog(fileUrl)
            }
        }

        FontDialog {
            id: memoFontDialog
            onAccepted: catalog.memoFont = font
        }
    }
}
