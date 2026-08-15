import QtQuick
import QtQuick.Layouts
import Quickshell

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 36
        color: "#cc1a1b26"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
                text: "◆ Lumarchy"
                color: "#7aa2f7"
                font.bold: true
                font.pixelSize: 15
            }

            Item { Layout.fillWidth: true }

            Text {
                id: clock
                color: "#c0caf5"
                font.pixelSize: 14
                text: Qt.formatDateTime(new Date(), "ddd  yyyy-MM-dd  hh:mm")

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd  yyyy-MM-dd  hh:mm")
                }
            }
        }
    }
}
