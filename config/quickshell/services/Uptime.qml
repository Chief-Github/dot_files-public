pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root


  property string uptimeText: ""

  Process {
      id: uptimeProcess
      command: ["/bin/sh", "-c", "cat /proc/uptime"]
      running: true
      stdout: SplitParser {
          onRead: data => {
              const secs = parseFloat(data.split(" ")[0])
              const d = Math.floor(secs / 86400)
              const h = Math.floor((secs % 86400) / 3600)
              const m = Math.floor((secs % 3600) / 60)
              root.uptimeText = d > 0 ? `${d}d ${h}h ${m}m` : h > 0 ? `${h}h ${m}m` :
   `${m}m`
          }
      }
  }

  Timer {
      interval: 5000
      running: true
      repeat: true
      onTriggered: uptimeProcess.running = true
  }
}
