import QtQuick 2.7
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

// TODO: add keyboard switching: Ctrl+Tab / Ctrl+Shift+Tab

Rectangle {
    property CatalogHandler catalog: null
    property MainController controller: null
    property int currentMemoId: 0

    Connections {
        target: catalog

        onMemoChanged: {
            var index = __getItemIndex(memoData.memoId)
            if (index >= 0)
                memosListModel.setProperty(index, "memoTitle", memoData.memoTitle)
        }

        onFolderRenamed: {
            // TODO: We can't say if a memo is in one of subfolders
            // of the given folder, so just update all paths for now
            for (var i = 0; i < memosListModel.count; i++) {
                var info = catalog.getMemoInfo(memosListModel.get(i).memoId)
                memosListModel.setProperty(i, "memoPath", info.memoPath)
            }
        }
    }

    Connections {
        target: controller

        onMemoOpened: {
            if (memoId === currentMemoId) return
            var index = __getItemIndex(memoId)
            if (index < 0) {
                var info = catalog.getMemoInfo(memoId)
                if (info) {
                    info.modified = false
                    memosListModel.append(info)
                    index = memosListModel.count-1
                }
            }
            currentMemoId = memoId
            memosListView.currentIndex = index
        }

        onMemoClosed: {
            var index = __getItemIndex(memoId)
            if (index > -1) {
                memosListModel.remove(index, 1)
                memosListView.currentIndex = Math.min(memosListModel.count-1, index)
                currentMemoId = __getMemoId(memosListView.currentIndex)
            }
        }

        onAllMemosClosed: {
            memosListModel.clear()
            currentMemoId = 0
        }

        onMemoModified: {
            var index = __getItemIndex(memoId)
            if (index > -1)
                memosListModel.setProperty(index, "modified", modified)
        }
    }

    function getAllIdsStr() {
        var ids = []
        for (var i = 0; i < memosListModel.count; i++)
            ids.push(memosListModel.get(i).memoId)
        return ids.join(';')
    }

    function setAllIdsStr(idsStr, activeId) {
        var memoIdsStr = idsStr.split(';')
        for (var i = 0; i < memoIdsStr.length; i++) {
            var memoId = parseInt(memoIdsStr[i])
            if (memoId > 0 && catalog.isValidId(memoId))
                controller.openMemo(memoId)
        }
    }

    function __getMemoId(index) {
        return (index > -1 && index < memosListModel.count) ? memosListModel.get(index).memoId : 0;
    }

    function __getItemIndex(memoId) {
        for (var i = 0; i < memosListModel.count; i++)
            if (memosListModel.get(i).memoId === memoId)
                return i
        return -1
    }

    ListModel {
        id: memosListModel
    }

    ListView {
        id: memosListView
        model: memosListModel
        spacing: 3
        anchors.fill: parent
        focus: true

        onCurrentIndexChanged: {
            var memoId = __getMemoId(currentIndex)
            if (memoId > 0 &&  memoId !== currentMemoId)
                controller.openMemo(memoId)
        }

        delegate: Rectangle {
            id: memoItemDelegate
            width: parent.width
            height: 40
            color: ListView.isCurrentItem ? Appearance.selectionColor() : Appearance.editorColor()
            property bool selected: ListView.isCurrentItem

            MouseArea {
                anchors.fill: parent
                onClicked: memosListView.currentIndex = index
            }

            RowLayout {
                anchors.fill: parent

                Rectangle {
                    id: iconPlace
                    color: memoItemDelegate.color
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 36
                    Layout.leftMargin: 0

                    Image {
                        id: memoIcon
                        source: model.memoIconPath
                        mipmap: true
                        smooth: true
                        anchors.left: iconPlace.left
                        anchors.top: iconPlace.top
                        anchors.leftMargin: 6
                        anchors.topMargin: 6
                        width: 24
                        height: 24
                    }

                    Image {
                        visible: model.modified
                        source: "qrc:/icon/modified"
                        anchors.left: iconPlace.left
                        anchors.top: iconPlace.top
                        anchors.leftMargin: 2
                        anchors.topMargin: 2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3

                    Label {
                        text: model.memoTitle
                        color: memoItemDelegate.selected ? Appearance.textColorSelected() : Appearance.textColor()
                        font.pointSize: Appearance.fontSizeDefaultUI()
                        font.bold: memoItemDelegate.selected
                        Layout.fillWidth: true
                    }

                    Label {
                        text: model.memoPath
                        color: memoItemDelegate.selected ? Appearance.textColorSelected() : Appearance.textColorModest()
                        font.pointSize: Appearance.fontSizeSmallUI()
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Image {
                        id: closeButton
                        source: "qrc:/toolbar/memo_close"
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: 16
                        Layout.rightMargin: 3
                        MouseArea {
                            anchors.fill: parent
                            onClicked: controller.needToCloseMemo(model.memoId)
                        }
                    }
                }
            }
        }
    }
}