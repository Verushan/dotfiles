// A login screen that looks like the qtile session it opens, in whichever
// qtile theme was current when ~/.config/sddm/install.sh last ran.
//
// The bar along the top is the qtile bar, rebuilt with its colours, font,
// margins and spacing (~/.config/qtile/settings/widgets.py), so logging in
// feels like the bar is already there. The middle of the screen holds only the
// login itself.

import QtQuick 2.15
import QtQml 2.15

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: theme.dark

    // ~/.config/qtile/themes/<theme>.json, which install.sh writes into
    // theme.conf; the fallbacks are kanagawa-dragon.json.
    readonly property QtObject theme: QtObject {
        readonly property color dark: config.dark || "#1d1c19"
        readonly property color grey: config.grey || "#2a2a2e"
        readonly property color light: config.light || "#c5c9c5"
        readonly property color focus: config.focus || "#22222e"
        readonly property color urgent: config.urgent || "#c4746e"
        readonly property color active: config.active || "#87a987"
        readonly property color inactive: config.inactive || "#282727"
        readonly property color color1: config.color1 || "#8ba4b0"
        readonly property color color2: config.color2 || "#8a9a7b"
        readonly property color color4: config.color4 || "#b6927b"
        readonly property color color5: config.color5 || "#8992a7"
        readonly property color color6: config.color6 || "#8ea4a2"
        // widgets.py: shade("light", 0.35), the colour of the bar's rules
        readonly property color rule: config.rule || "#585955"
        // The placeholder text, dimmed the same way
        readonly property color hint: config.hint || "#64665f"
    }

    readonly property string fontFamily: config.font || "JetBrainsMono Nerd Font"
    readonly property int fontSize: 15

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool busy: false
    property bool failed: false
    // Set once sddm has been asked and the answer is slow in coming.
    property bool waiting: false

    // Fired as the launch begins, so every password dot can ripple in turn.
    signal launched

    // A glyph or reading on the bar, set in the bar's own font.
    component BarText: Text {
        height: 32
        verticalAlignment: Text.AlignVCenter
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.bold: true
        color: theme.light
    }

    // widgets.py's divider(): a 1px rule over 55% of the bar's height.
    component Rule: Rectangle {
        width: 1
        height: 32 * 0.55
        anchors.verticalCenter: parent.verticalCenter
        color: theme.rule
    }

    // A bar glyph that does something when clicked.
    component BarButton: BarText {
        id: button

        property string label
        readonly property bool hovered: area.containsMouse
        signal clicked

        opacity: hovered ? 1 : 0.8

        MouseArea {
            id: area

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // The users and sessions sddm knows about, readable by index.
    Instantiator {
        id: users
        model: userModel
        delegate: QtObject { readonly property string name: model.name }
    }

    Instantiator {
        id: sessions
        model: sessionModel
        delegate: QtObject { readonly property string name: model.name }
    }

    // Reads sessions.count so that bindings calling this re-evaluate once the
    // Instantiator has built its objects.
    function sessionName(index) {
        var session = sessions.count > 0 ? sessions.objectAt(index) : null
        return session ? session.name.toLowerCase() : ""
    }

    function cycleSession(step) {
        if (sessions.count > 0)
            sessionIndex = (sessionIndex + step + sessions.count) % sessions.count
    }

    function cycleUser(step) {
        if (users.count < 2)
            return

        var current = 0
        for (var i = 0; i < users.count; i++)
            if (users.objectAt(i).name === username.text)
                current = i

        username.text = users.objectAt((current + step + users.count) % users.count).name
        password.text = ""
    }

    function login() {
        if (busy || username.text === "")
            return

        busy = true
        failed = false
        // sddm tears the greeter down within a few dozen milliseconds of a
        // successful login, too soon to animate anything, so the screen
        // clears first and the password goes to sddm at the end of it.
        launch.restart()
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            launch.stop()
            restore.restart()
        }
    }

    Image {
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    // Comes over the picture as the login launches, leaving only the bar on
    // its own colour - the screen qtile is about to draw.
    Rectangle {
        id: veil

        anchors.fill: parent
        color: theme.dark
        opacity: 0
    }

    // A light running along a short line, for an answer that takes a moment.
    Item {
        id: pending

        anchors.centerIn: parent
        width: 160
        height: 2
        clip: true
        opacity: waiting ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            color: theme.grey
        }

        Rectangle {
            width: 60
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: theme.color1 }
                GradientStop { position: 1; color: "transparent" }
            }

            NumberAnimation on x {
                from: -60
                to: 160
                duration: 900
                loops: Animation.Infinite
                running: pending.visible
            }
        }
    }

    // The bar ------------------------------------------------------------------

    Rectangle {
        id: bar

        visible: primaryScreen
        // screens.py: a 32px bar inset by half the window gap on every side.
        x: 5
        y: 5
        width: parent.width - 10
        height: 32
        // picom rounds the qtile bar by its QTILE_INTERNAL rule.
        radius: 15
        color: theme.dark

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 15
            height: parent.height

            // U+F322, the font-logos linux-endeavour mark the qtile bar opens
            // with - drawn whole here, where the bar's TextBox clips its left edge.
            BarText {
                text: ""
                color: theme.color5
                topPadding: -4
            }
            Item { width: 10; height: 1 }
            Rule {}
            Item { width: 9; height: 1 }
            BarText {
                id: clock

                color: theme.color1
                text: Qt.formatDateTime(new Date(), config.clockFormat || "dddd dd MMMM HH:mm")

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.text = Qt.formatDateTime(new Date(), config.clockFormat || "dddd dd MMMM HH:mm")
                }
            }
        }

        // The session sits where the workspaces do, drawn like the current
        // group: a block of the focus colour edge to edge. Click or scroll to
        // change it.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            width: sessionRow.width + 28
            color: theme.focus
            visible: sessions.count > 0

            Row {
                id: sessionRow

                anchors.centerIn: parent
                spacing: 10

                BarText {
                    text: "󰅁"
                    color: theme.rule
                    visible: sessions.count > 1
                }
                BarText {
                    text: sessionName(sessionIndex)
                    color: theme.active
                }
                BarText {
                    text: "󰅂"
                    color: theme.rule
                    visible: sessions.count > 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: sessions.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => cycleSession(mouse.button === Qt.RightButton ? -1 : 1)
                onWheel: (wheel) => cycleSession(wheel.angleDelta.y > 0 ? -1 : 1)
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 15
            height: parent.height
            spacing: 14

            // Names whichever power button is under the pointer.
            BarText {
                id: powerHint

                color: theme.hint
                font.bold: false
            }

            BarButton {
                text: "󰤄"
                label: "suspend"
                color: theme.color6
                visible: sddm.canSuspend
                onClicked: sddm.suspend()
                onHoveredChanged: powerHint.text = hovered ? label : ""
            }
            BarButton {
                text: "󰜉"
                label: "reboot"
                color: theme.color4
                visible: sddm.canReboot
                onClicked: sddm.reboot()
                onHoveredChanged: powerHint.text = hovered ? label : ""
            }
            BarButton {
                text: "󰐥"
                label: "shut down"
                color: theme.urgent
                visible: sddm.canPowerOff
                onClicked: sddm.powerOff()
                onHoveredChanged: powerHint.text = hovered ? label : ""
            }
        }
    }

    // The login ----------------------------------------------------------------

    Column {
        id: loginForm

        visible: primaryScreen
        anchors.centerIn: parent
        spacing: 14
        opacity: 0

        // x shakes it on a wrong password, y lifts it in and out.
        transform: Translate { id: nudge }

        Component.onCompleted: {
            username.text = userModel.lastUser || (users.count > 0 ? users.objectAt(0).name : "")
            if (username.text === "")
                username.forceActiveFocus()
            else
                password.forceActiveFocus()
            intro.start()
        }

        // The user, as plain text - click to type another name, or use
        // up/down to step through the accounts on this machine.
        TextInput {
            id: username

            anchors.horizontalCenter: parent.horizontalCenter
            width: box.width
            horizontalAlignment: TextInput.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 22
            font.bold: true
            color: theme.light
            selectionColor: theme.grey
            selectByMouse: true
            clip: true
            readOnly: busy
            KeyNavigation.tab: password
            KeyNavigation.backtab: password

            Keys.onReturnPressed: password.forceActiveFocus()
            Keys.onEnterPressed: password.forceActiveFocus()
            Keys.onUpPressed: cycleUser(-1)
            Keys.onDownPressed: cycleUser(1)

            Text {
                anchors.centerIn: parent
                visible: !username.text
                text: "username"
                font: username.font
                color: theme.hint
            }
        }

        // The password, boxed like a focused qtile window: a 2px border in
        // the layout's border_focus colour, urgent once a try has failed.
        Rectangle {
            id: box

            width: 380
            height: 46
            color: theme.dark
            border.width: 2
            border.color: busy ? theme.color1
                        : failed ? theme.urgent
                        : password.activeFocus ? theme.active
                        : theme.grey

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // An outline that swells off the box and fades with each key.
            Rectangle {
                id: ring

                property real grow: 0

                anchors.centerIn: parent
                width: parent.width + grow
                height: parent.height + grow
                z: -1
                color: "transparent"
                border.width: 2
                border.color: theme.active
                opacity: 0
            }

            ParallelAnimation {
                id: keystroke

                NumberAnimation { target: ring; property: "grow"; from: 0; to: 16; duration: 380; easing.type: Easing.OutCubic }
                NumberAnimation { target: ring; property: "opacity"; from: 0.45; to: 0; duration: 380; easing.type: Easing.OutCubic }
            }

            // A light that runs along the bottom edge as the login launches.
            Item {
                anchors.fill: parent
                clip: true

                Rectangle {
                    id: streak

                    x: -width
                    y: parent.height - height
                    width: 90
                    height: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: theme.light }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }

            NumberAnimation {
                id: sweep

                target: streak
                property: "x"
                from: -streak.width
                to: box.width
                duration: 420
                easing.type: Easing.InOutQuad
            }

            BarText {
                id: lock

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌾"
                color: box.border.color
                font.pixelSize: 17
            }

            // Takes the keys, but draws nothing: the dots below stand in for
            // its text.
            TextInput {
                id: password

                anchors.left: lock.right
                anchors.leftMargin: 12
                anchors.right: enter.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordMaskDelay: 0
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                cursorDelegate: Item {}
                clip: true
                readOnly: busy
                KeyNavigation.tab: username
                KeyNavigation.backtab: username

                onTextChanged: {
                    if (text) {
                        failed = false
                        placeholderIn.stop()
                        placeholder.opacity = 0
                    } else {
                        placeholderIn.restart()
                    }

                    while (dotModel.count < length) {
                        dotModel.append({ n: dotModel.count })
                        keystroke.restart()
                    }
                    while (dotModel.count > length)
                        dotModel.remove(dotModel.count - 1)
                    Qt.callLater(dots.positionViewAtEnd)
                }
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
                Keys.onEscapePressed: text = ""

                Text {
                    id: placeholder

                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: busy ? "logging in…" : "password"
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                    color: theme.hint
                }

                // Back once the last dots have dropped out of its way.
                SequentialAnimation {
                    id: placeholderIn

                    PauseAnimation { duration: 180 }
                    NumberAnimation { target: placeholder; property: "opacity"; to: 1; duration: 200 }
                }
            }

            ListModel { id: dotModel }

            // One dot a character: each pops in with a flash of the active
            // colour, drops away when deleted, and the row ripples in color1
            // as the login goes.
            ListView {
                id: dots

                readonly property real rippleStep: count > 0 ? Math.min(28, 260 / count) : 0

                anchors.fill: password
                orientation: ListView.Horizontal
                spacing: 6
                interactive: false
                clip: true
                model: dotModel

                delegate: Item {
                    id: slot

                    required property int index

                    width: 9
                    height: dots.height

                    Rectangle {
                        id: dot

                        anchors.centerIn: parent
                        width: 9
                        height: 9
                        radius: 4.5
                        color: failed ? theme.urgent : theme.light
                        transform: Translate { id: hop }

                        Rectangle {
                            id: flash

                            anchors.fill: parent
                            radius: parent.radius
                            color: busy ? theme.color1 : theme.active
                            opacity: 0
                            // The ripple leaves it lit; a wrong password
                            // shows the red beneath.
                            visible: !failed
                        }
                    }

                    Component.onCompleted: fresh.start()

                    NumberAnimation {
                        id: fresh

                        target: flash
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 450
                        easing.type: Easing.InQuad
                    }

                    SequentialAnimation {
                        id: ripple

                        PauseAnimation { duration: Math.max(0, slot.index) * dots.rippleStep }
                        ParallelAnimation {
                            NumberAnimation { target: hop; property: "y"; to: -6; duration: 110; easing.type: Easing.OutQuad }
                            NumberAnimation { target: flash; property: "opacity"; to: 1; duration: 110 }
                        }
                        NumberAnimation { target: hop; property: "y"; to: 0; duration: 200; easing.type: Easing.OutBounce }
                    }

                    Connections {
                        target: root

                        function onLaunched() { ripple.restart() }
                    }
                }

                add: Transition {
                    NumberAnimation { property: "scale"; from: 0; to: 1; duration: 220; easing.type: Easing.OutBack }
                }

                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "scale"; to: 0.2; duration: 200; easing.type: Easing.InQuad }
                        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                        NumberAnimation { property: "y"; to: 10; duration: 200; easing.type: Easing.InQuad }
                    }
                }

                // The caret, after the last dot.
                footer: Item {
                    width: 14
                    height: dots.height

                    Rectangle {
                        x: dots.count > 0 ? 6 : 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 18
                        color: theme.active
                        visible: password.activeFocus && !busy

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: password.activeFocus && !busy

                            NumberAnimation { to: 1; duration: 0 }
                            PauseAnimation { duration: 530 }
                            NumberAnimation { to: 0; duration: 120 }
                            PauseAnimation { duration: 380 }
                            NumberAnimation { to: 1; duration: 120 }
                        }
                    }
                }
            }

            BarButton {
                id: enter

                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁔"
                color: theme.color1
                visible: password.text !== "" && !busy
                onClicked: root.login()
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: enter.visible ? 40 : 0
                cursorShape: Qt.IBeamCursor
                onClicked: password.forceActiveFocus()
            }
        }

        // One quiet line for the only two things worth saying here. Given a
        // width so the column keeps its place while the line is empty.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: box.width
            height: 18
            horizontalAlignment: Text.AlignHCenter
            font.family: root.fontFamily
            font.pixelSize: 13
            text: failed ? "incorrect password"
                : keyboard.capsLock ? "󰪛  caps lock is on"
                : ""
            color: failed ? theme.urgent : theme.color4
        }
    }

    // The login rises into place as the greeter starts.
    ParallelAnimation {
        id: intro

        NumberAnimation { target: loginForm; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: nudge; property: "y"; from: 14; to: 0; duration: 600; easing.type: Easing.OutCubic }
    }

    // Enter: the dots ripple and a light runs along the box, then the login
    // lifts away and the picture goes dark under the bar. Only then is sddm
    // asked, so a good password leaves on this last frame.
    SequentialAnimation {
        id: launch

        ScriptAction {
            script: {
                intro.stop()
                root.launched()
                sweep.restart()
            }
        }
        PauseAnimation { duration: 330 }
        ParallelAnimation {
            NumberAnimation { target: loginForm; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InCubic }
            NumberAnimation { target: loginForm; property: "scale"; to: 0.96; duration: 300; easing.type: Easing.InCubic }
            NumberAnimation { target: nudge; property: "y"; to: -18; duration: 300; easing.type: Easing.InCubic }
            NumberAnimation { target: veil; property: "opacity"; to: 1; duration: 380; easing.type: Easing.InOutQuad }
        }
        ScriptAction {
            script: {
                waitTimer.start()
                sddm.login(username.text, password.text, sessionIndex)
            }
        }
    }

    // Only show the pending line if the answer is slow enough to wonder about.
    Timer {
        id: waitTimer

        interval: 350
        onTriggered: waiting = true
    }

    // A wrong password: the login comes back, its dots fall away red, and it
    // shakes.
    SequentialAnimation {
        id: restore

        ScriptAction {
            script: {
                waitTimer.stop()
                waiting = false
            }
        }
        ParallelAnimation {
            NumberAnimation { target: veil; property: "opacity"; to: 0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: loginForm; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: loginForm; property: "scale"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: nudge; property: "y"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        }
        ScriptAction {
            script: {
                busy = false
                failed = true
                password.text = ""
                password.forceActiveFocus()
                shake.restart()
            }
        }
    }

    SequentialAnimation {
        id: shake

        loops: 1
        NumberAnimation { target: nudge; property: "x"; to: -10; duration: 50 }
        NumberAnimation { target: nudge; property: "x"; to: 10; duration: 70 }
        NumberAnimation { target: nudge; property: "x"; to: -6; duration: 60 }
        NumberAnimation { target: nudge; property: "x"; to: 4; duration: 50 }
        NumberAnimation { target: nudge; property: "x"; to: 0; duration: 40 }
    }
}
