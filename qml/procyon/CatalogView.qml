import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQml.Models 2.2

import "appearance.js" as Appearance

Rectangle {
    property variant catalogModel
    signal needToOpenMemo(int memoId)

    function getSelectedMemoId() {
        if (memoSelector.hasSelection && memoSelector.currentIndex) {
            var indexData = catalogModel.data(memoSelector.currentIndex)
            return (indexData && !indexData.isFolder) ? indexData.memoId : -1
        }
        return -1
    }

    function getTreeItemIconPath(styleData) {
        if (!styleData.value) return ""
        if (styleData.value.isFolder) {
            if (styleData.isExpanded )
                return "qrc:/icon/folder_opened"
            return "qrc:/icon/folder_closed"
        }
        return styleData.value.memoIconPath
    }

    TreeView {
        model: catalogModel
        headerVisible: false
        anchors.fill: parent

        selection: ItemSelectionModel {
            id: memoSelector
            model: catalogModel
        }

        rowDelegate: Rectangle {
            height: 22 // TODO: should be somehow depended on icon size and font size
            color: styleData.selected ? Appearance.selectionColor() : Appearance.editorColor()
        }

        itemDelegate: Row {
            spacing: 4
            Image {
                source: getTreeItemIconPath(styleData)
                mipmap: true
                smooth: true
                height: 16
                width: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: styleData.value ? styleData.value.memoTitle : ""
                font { pointSize: 10; bold: styleData.selected }
                color: styleData.selected ? Appearance.textColorSelected() : Appearance.textColor()
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        onDoubleClicked: {
            var indexData = catalogModel.data(index)
            if (indexData.isFolder) {
                if (isExpanded(index))
                    collapse(index)
                else
                    expand(index)
            }
            else needToOpenMemo(indexData.memoId)
        }

        TableViewColumn { role: "display" }
    }
}
