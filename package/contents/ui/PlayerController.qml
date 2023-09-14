/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>
    SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2 as Kirigami
import org.kde.plasma.private.mpris as Mpris

RowLayout {
    enabled: toolTipDelegate.playerData.canControl

    readonly property bool isPlaying: toolTipDelegate.playerData.playbackStatus === Mpris.PlaybackStatus.Playing

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: isWin ? Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit
        spacing: 0

        ScrollableTextWrapper {
            id: songTextWrapper

            Layout.fillWidth: true
            Layout.preferredHeight: songText.height
            implicitWidth: songText.implicitWidth

            PlasmaComponents3.Label {
                id: songText
                parent: songTextWrapper
                width: parent.width
                height: undefined
                lineHeight: 1
                maximumLineCount: artistText.visible? 1 : 2
                wrapMode: Text.NoWrap
                elide: parent.state ? Text.ElideNone : Text.ElideRight
                text: toolTipDelegate.playerData.track
                textFormat: Text.PlainText
            }
        }

        ScrollableTextWrapper {
            id: artistTextWrapper

            Layout.fillWidth: true
            Layout.preferredHeight: artistText.height
            implicitWidth: artistText.implicitWidth
            visible: artistText.text.length > 0

            PlasmaExtras.DescriptiveLabel {
                id: artistText
                parent: artistTextWrapper
                width: parent.width
                height: undefined
                wrapMode: Text.NoWrap
                lineHeight: 1
                elide: parent.state ? Text.ElideNone : Text.ElideRight
                text: toolTipDelegate.playerData.artist
                font: Kirigami.Theme.smallFont
                textFormat: Text.PlainText
            }
        }
    }

    PlasmaComponents3.ToolButton {
        enabled: toolTipDelegate.playerData.canGoPrevious
        icon.name: LayoutMirroring.enabled ? "media-skip-forward" : "media-skip-backward"
        onClicked: toolTipDelegate.playerData.Previous()
    }

    PlasmaComponents3.ToolButton {
        enabled: isPlaying ? toolTipDelegate.playerData.canPause : toolTipDelegate.playerData.canPlay
        icon.name: isPlaying ? "media-playback-pause" : "media-playback-start"
        onClicked: {
            if (!isPlaying) {
                toolTipDelegate.playerData.Play();
            } else {
                toolTipDelegate.playerData.Pause();
            }
        }
    }

    PlasmaComponents3.ToolButton {
        enabled: toolTipDelegate.playerData.canGoNext
        icon.name: LayoutMirroring.enabled ? "media-skip-backward" : "media-skip-forward"
        onClicked: toolTipDelegate.playerData.Next()
    }
}
