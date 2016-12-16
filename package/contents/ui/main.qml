/***************************************************************************
 *   Copyright (C) 2012-2016 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.taskmanager 0.1 as TaskManager
import org.kde.plasma.private.taskmanager 0.1 as TaskManagerApplet

import "../code/layout.js" as LayoutManager
import "../code/tools.js" as TaskTools

Item {
    id: tasks

    anchors.fill: parent

    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)
    property bool iconsOnly: (plasmoid.pluginName == "org.kde.plasma.icontasks")

    property QtObject contextMenuComponent: Qt.createComponent("ContextMenu.qml");

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    Layout.fillWidth: true
    Layout.fillHeight:true
    Layout.minimumWidth: tasks.vertical ? 0 : LayoutManager.preferredMinWidth()
    Layout.minimumHeight: !tasks.vertical ? 0 : LayoutManager.preferredMinHeight()

//BEGIN TODO: this is not precise enough: launchers are smaller than full tasks
    Layout.preferredWidth: tasks.vertical ? units.gridUnit * 10 : ((LayoutManager.logicalTaskCount() * LayoutManager.preferredMaxWidth()) / LayoutManager.calculateStripes());
    Layout.preferredHeight: tasks.vertical ? ((LayoutManager.logicalTaskCount() * LayoutManager.preferredMaxHeight()) / LayoutManager.calculateStripes()) : units.gridUnit * 2;
//END TODO

    property Item dragSource: null

    signal requestLayout
    signal windowsHovered(variant winIds, bool hovered)
    signal presentWindows(variant winIds)

    onWidthChanged: {
        taskList.width = LayoutManager.layoutWidth();

        if (plasmoid.configuration.forceStripes) {
            taskList.height = LayoutManager.layoutHeight();
        }
    }

    onHeightChanged: {
        if (plasmoid.configuration.forceStripes) {
            taskList.width = LayoutManager.layoutWidth();
        }

        taskList.height = LayoutManager.layoutHeight();
    }

    onDragSourceChanged: {
        if (dragSource == null) {
            tasksModel.syncLaunchers();
        }
    }

    TaskManager.TasksModel {
        id: tasksModel

        virtualDesktop: virtualDesktopInfo.currentDesktop
        screenGeometry: plasmoid.screenGeometry
        activity: activityInfo.currentActivity

        filterByVirtualDesktop: plasmoid.configuration.showOnlyCurrentDesktop
        filterByScreen: plasmoid.configuration.showOnlyCurrentScreen
        filterByActivity: plasmoid.configuration.showOnlyCurrentActivity
        filterNotMinimized: plasmoid.configuration.showOnlyMinimized

        sortMode: iconsOnly ? TaskManager.TasksModel.SortManual
            : sortModeEnumValue(plasmoid.configuration.sortingStrategy)
        launchInPlace: iconsOnly
        separateLaunchers: {
            if (!iconsOnly && !plasmoid.configuration.separateLaunchers
                && plasmoid.configuration.sortingStrategy == 1) {
                return false;
            }

            return true;
        }

        groupMode: iconsOnly ? TaskManager.TasksModel.GroupApplication
            : sortModeEnumValue(plasmoid.configuration.groupingStrategy)
        groupInline: !plasmoid.configuration.groupPopups
        groupingWindowTasksThreshold: (plasmoid.configuration.onlyGroupWhenFull && !iconsOnly
            ? LayoutManager.optimumCapacity(width, height) + 1 : -1)

        onLauncherListChanged: {
            layoutTimer.restart();
            plasmoid.configuration.launchers = launcherList;
        }

        onGroupingAppIdBlacklistChanged: {
            plasmoid.configuration.groupingAppIdBlacklist = groupingAppIdBlacklist;
        }

        onGroupingLauncherUrlBlacklistChanged: {
            plasmoid.configuration.groupingLauncherUrlBlacklist = groupingLauncherUrlBlacklist;
        }

        function sortModeEnumValue(index) {
            switch (index) {
                case 0:
                    return TaskManager.TasksModel.SortDisabled;
                case 1:
                    return TaskManager.TasksModel.SortManual;
                case 2:
                    return TaskManager.TasksModel.SortAlpha;
                case 3:
                    return TaskManager.TasksModel.SortVirtualDesktop;
                case 4:
                    return TaskManager.TasksModel.SortActivity;
                default:
                    return TaskManager.TasksModel.SortDisabled;
            }
        }

        function groupModeEnumValue(index) {
            switch (index) {
                case 0:
                    return TaskManager.TasksModel.GroupDisabled;
                case 1:
                    return TaskManager.TasksModel.GroupApplications;
            }
        }

        Component.onCompleted: {
            launcherList = plasmoid.configuration.launchers;
            groupingAppIdBlacklist = plasmoid.configuration.groupingAppIdBlacklist;
            groupingLauncherUrlBlacklist = plasmoid.configuration.groupingLauncherUrlBlacklist;

            // Only hook up view only after the above churn is done.
            taskRepeater.model = tasksModel;
        }
    }

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManagerApplet.Backend {
        id: backend

        taskManagerItem: groupDialog.visible ? null : tasks
        toolTipItem: toolTipDelegate
        highlightWindows: plasmoid.configuration.highlightWindows

        onAddLauncher: {
            tasks.addLauncher(url);
        }
    }

    PlasmaCore.DataSource {
        id: mpris2Source
        engine: "mpris2"
        connectedSources: sources

        function sourceNameForLauncherUrl(launcherUrl) {
            if (!launcherUrl) {
                return "";
            }

            // MPRIS spec explicitly mentions that "DesktopEntry" is with .desktop extension trimmed
            // Moreover, remove URL parameters, like wmClass (part after the question mark)
            var desktopFileName = launcherUrl.toString().split('/').pop().split('?')[0].replace(".desktop", "")

            for (var i = 0, length = sources.length; i < length; ++i) {
                var source = sources[i];
                var sourceData = data[source];

                if (sourceData && sourceData.DesktopEntry === desktopFileName) {
                    return source
                }
            }

            return ""
        }

        function startOperation(source, op) {
            var service = serviceForSource(source)
            var operation = service.operationDescription(op)
            return service.startOperationCall(operation)
        }

        function goPrevious(source) {
            startOperation(source, "Previous");
        }
        function goNext(source) {
            startOperation(source, "Next");
        }
        function playPause(source) {
            startOperation(source, "PlayPause");
        }
        function stop(source) {
            startOperation(source, "Stop");
        }
        function raise(source) {
            startOperation(source, "Raise");
        }
        function quit(source) {
            startOperation(source, "Quit");
        }
    }

    Timer {
        id: iconGeometryTimer

        interval: 500
        repeat: false

        onTriggered: {
            TaskTools.publishIconGeometries(taskList.children);
        }
    }

    Binding {
        target: plasmoid
        property: "status"
        value: (tasksModel.anyTaskDemandsAttention
            ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.PassiveStatus)
    }

    Connections {
        target: plasmoid

        onLocationChanged: {
            // This is on a timer because the panel may not have
            // settled into position yet when the location prop-
            // erty updates.
            iconGeometryTimer.start();
        }
    }

    Connections {
        target: plasmoid.configuration

        onLaunchersChanged: tasksModel.launcherList = plasmoid.configuration.launchers
        onGroupingAppIdBlacklistChanged: tasksModel.groupingAppIdBlacklist = plasmoid.configuration.groupingAppIdBlacklist;
        onGroupingLauncherUrlBlacklistChanged: tasksModel.groupingLauncherUrlBlacklist = plasmoid.configuration.groupingLauncherUrlBlacklist;
    }

    TaskManagerApplet.DragHelper {
        id: dragHelper

        dragIconSize: units.iconSizes.medium
    }

    PlasmaCore.FrameSvgItem {
        id: taskFrame

        visible: false;

        imagePath: "widgets/tasks";
        prefix: "normal"
    }

    PlasmaCore.Svg {
        id: taskSvg

        imagePath: "widgets/tasks"
    }

    MouseHandler {
        id: mouseHandler

        anchors.fill: parent

        target: taskList

        onUrlsDropped: {
            // If all dropped URLs point to application desktop files, we'll add a launcher for each of them.
            var createLaunchers = urls.every(function (item) {
                return backend.isApplication(item)
            });

            if (createLaunchers) {
                urls.forEach(function (item) {
                    addLauncher(item);
                });
                return;
            }

            if (!hoveredItem) {
                return;
            }

            // DeclarativeMimeData urls is a QJsonArray but requestOpenUrls expects a proper QList<QUrl>.
            var urlsList = backend.jsonArrayToUrlList(urls);

            // Otherwise we'll just start a new instance of the application with the URLs as argument,
            // as you probably don't expect some of your files to open in the app and others to spawn launchers.
            tasksModel.requestOpenUrls(hoveredItem.modelIndex(), urlsList);
        }
    }

    ToolTipDelegate {
        id: toolTipDelegate

        visible: false
    }

    TaskList {
        id: taskList

        anchors {
            left: parent.left
            top: parent.top
        }

        onWidthChanged: LayoutManager.layout(taskRepeater)
        onHeightChanged: LayoutManager.layout(taskRepeater)

        flow: {
            if (tasks.vertical) {
                return plasmoid.configuration.forceStripes ? Flow.LeftToRight : Flow.TopToBottom
            }
            return plasmoid.configuration.forceStripes ? Flow.TopToBottom : Flow.LeftToRight
        }

        onAnimatingChanged: {
            if (!animating) {
                TaskTools.publishIconGeometries(children);
            }
        }

        function layout() {
            taskList.width = LayoutManager.layoutWidth();
            taskList.height = LayoutManager.layoutHeight();
            LayoutManager.layout(taskRepeater);
        }

        Timer {
            id: layoutTimer

            interval: 0
            repeat: false

            onTriggered: taskList.layout()
        }

        Repeater {
            id: taskRepeater

            delegate: Task {}

            onItemAdded: taskList.layout()
            onItemRemoved: taskList.layout()
        }
    }

    GroupDialog { id: groupDialog }

    function hasLauncher(url) {
        return tasksModel.launcherPosition(url) != -1;
    }

    function addLauncher(url) {
        if (plasmoid.immutability !== PlasmaCore.Types.SystemImmutable) {
            tasksModel.requestAddLauncher(url);
        }
    }

    function resetDragSource() {
        dragSource = null;
    }

    function createContextMenu(task) {
        var menu = tasks.contextMenuComponent.createObject(task);
        menu.visualParent = task;
        menu.mpris2Source = mpris2Source;
        return menu;
    }

    Component.onCompleted: {
        tasks.requestLayout.connect(layoutTimer.restart);
        tasks.requestLayout.connect(iconGeometryTimer.restart);
        tasks.windowsHovered.connect(backend.windowsHovered);
        tasks.presentWindows.connect(backend.presentWindows);
        dragHelper.dropped.connect(resetDragSource);
    }
}
