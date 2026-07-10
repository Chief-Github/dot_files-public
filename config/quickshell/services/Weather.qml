// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string condition: "Loading"
    property string temperature: "--°C"
    property string humidity: "--%"
    property string icon: "󰖐"

    readonly property string weatherText:
        `${icon}  ${temperature}  •  ${condition}`

    function getWeatherIcon(cond) {
        cond = cond.toLowerCase()

        if (cond.includes("sun") || cond.includes("clear"))
            return "󰖙"

        if (cond.includes("cloud"))
            return "󰖐"

        if (cond.includes("rain"))
            return "󰖗"

        if (cond.includes("storm"))
            return "󰖓"

        if (cond.includes("snow"))
            return "󰖘"

        if (cond.includes("fog") || cond.includes("mist"))
            return "󰖑"

        return "󰖐"
    }

    Process {
        id: weatherProcess

        command: [
            "curl",
            "-s",
            "wttr.in/?format=%C|%t|%h"
        ]

        running: true

        stdout: SplitParser {
            onRead: data => {

                const parts = data.trim().split("|")

                if (parts.length >= 3) {

                    root.condition = parts[0]
                    root.temperature = parts[1]
                    root.humidity = parts[2]

                    root.icon =
                        root.getWeatherIcon(root.condition)
                }
            }
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true

        onTriggered:
            weatherProcess.running = true
    }
}