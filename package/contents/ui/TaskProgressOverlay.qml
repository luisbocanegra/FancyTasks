/*
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Templates 2.15 as T

import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasmoid 2.0

import "code/tools.js" as TaskTools

T.ProgressBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    hoverEnabled: false
    padding: 0

    contentItem: Item {
        clip: true

        KSvg.FrameSvgItem {
            id: progressFrame

            anchors.left: parent.left
            width: parent.width * control.position
            height: parent.height

            imagePath: "widgets/tasks"
            prefix: TaskTools.taskPrefix("progress", Plasmoid.location).concat(TaskTools.taskPrefix("hover", Plasmoid.location))
        }
    }

    background: null
}
