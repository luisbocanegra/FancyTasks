/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQml.Models 2.15
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Loader {
    id: toolTipDelegate

    property Item parentTask
    property var rootIndex

    property string appName
    property int pidParent
    property bool isGroup

    property var windows
    readonly property bool isWin: (windows?.length ?? 0) > 0

    property variant icon
    property url launcherUrl
    property bool isLauncher
    property bool isMinimizedParent

    // Needed for generateSubtext()
    property string displayParent
    property string genericName
    property var virtualDesktopParent
    property bool isOnAllVirtualDesktopsParent
    property var activitiesParent
    //
    property bool smartLauncherCountVisible
    property int smartLauncherCount

    property bool blockingUpdates: false

    readonly property bool isVerticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // This number controls the overall size of the window tooltips
    readonly property int tooltipInstanceMaximumWidth: Kirigami.Units.gridUnit * 16

    // These properties are required to make tooltip interactive when there is a player but no window is present.
    readonly property QtObject playerData: mpris2Source.playerForLauncherUrl(launcherUrl, pidParent)

    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: Layout.minimumWidth

    Layout.minimumHeight: implicitHeight
    Layout.maximumHeight: Layout.minimumHeight

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    active: !blockingUpdates && rootIndex !== undefined && ((parentTask && parentTask.containsMouse) || Window.visibility !== Window.Hidden)
    asynchronous: true

    sourceComponent: isGroup ? groupToolTip : singleTooltip

    Component {
        id: singleTooltip

        ToolTipInstance {
            submodelIndex: toolTipDelegate.rootIndex
        }
    }

    Component {
        id: groupToolTip

        PlasmaComponents3.ScrollView {
            // 2 * Kirigami.Units.smallSpacing is for the margin of tooltipDialog
            implicitWidth: leftPadding + rightPadding + Math.min(Screen.desktopAvailableWidth - 2 * Kirigami.Units.smallSpacing, Math.max(delegateModel.estimatedWidth, contentItem.contentItem.childrenRect.width))
            implicitHeight: bottomPadding + Math.min(Screen.desktopAvailableHeight - 2 * Kirigami.Units.smallSpacing, Math.max(delegateModel.estimatedHeight, contentItem.contentItem.childrenRect.height))

            ListView {
                id: groupToolTipListView

                model: delegateModel

                orientation: isVerticalPanel ? ListView.Vertical : ListView.Horizontal
                reuseItems: true
                spacing: Kirigami.Units.gridUnit
            }

            DelegateModel {
                id: delegateModel

                // On Wayland, a tooltip has a significant resizing process, so estimate the size first.
                readonly property real estimatedWidth: (toolTipDelegate.isVerticalPanel ? 1 : count) * (toolTipDelegate.tooltipInstanceMaximumWidth + Kirigami.Units.gridUnit) - Kirigami.Units.gridUnit
                readonly property real estimatedHeight: (toolTipDelegate.isVerticalPanel ? count : 1) * (toolTipDelegate.tooltipInstanceMaximumWidth / 2 + Kirigami.Units.gridUnit) - Kirigami.Units.gridUnit

                model: tasksModel

                rootIndex: toolTipDelegate.rootIndex
                onRootIndexChanged: groupToolTipListView.positionViewAtBeginning() // Fix a visual glitch (when the mouse moves from a tooltip with a moved scrollbar to another tooltip without a scrollbar)

                delegate: ToolTipInstance {
                    submodelIndex: tasksModel.makeModelIndex(toolTipDelegate.rootIndex.row, index)
                }
            }
        }
    }
}
