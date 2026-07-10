// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as QsServices

Singleton {
    id: root
    
    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool active: true
    
    property real cpuPerc: 0
    property real cpuTemp: 0
    property real memUsed: 0
    property real memTotal: 1
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property real diskUsed: 0
    property real diskTotal: 1
    readonly property real diskPerc: diskTotal > 0 ? diskUsed / diskTotal : 0
    
    // Network speed tracking
    property real downloadSpeed: 0  // bytes per second
    property real uploadSpeed: 0    // bytes per second
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastNetTime: 0
    property var networkHistory: []  // Array of {download, upload} for graphing
    
    // GPU monitoring
    property bool hasGpu: false
    property string gpuType: "none"  // "nvidia", "amd", "intel", "none"
    property real gpuUsage: 0        // percentage 0-100
    property real gpuTemp: 0         // celsius
    property real gpuMemUsed: 0      // MB
    property real gpuMemTotal: 0     // MB
    readonly property real gpuMemPerc: gpuMemTotal > 0 ? gpuMemUsed / gpuMemTotal : 0
    
    // Top processes
    property var topProcesses: []    // [{name, cpu, pid}, ...]
    
    property real lastCpuIdle: 0
    property real lastCpuTotal: 0
    
    Component.onCompleted: {
        detectGpu()
        updateTimer.start()
        updateCpu()
        updateCpuTemp()
        updateMemory()
        updateDisk()
        updateNetwork()
        updateTopProcesses()
    }
    
    function detectGpu() {
        gpuDetectProc.running = true
    }
    
    function updateCpu() {
        cpuProcess.running = true
    }
    
    function updateMemory() {
        memProcess.running = true
    }
    
    function updateDisk() {
        diskProcess.running = true
    }
    
    function updateNetwork() {
        networkProcess.running = true
    }
    
    function updateGpu() {
        if (!hasGpu) return
        
        if (gpuType === "nvidia") {
            nvidiaGpuProc.running = true
        } else if (gpuType === "amd") {
            amdGpuProc.running = true
        } else if (gpuType === "intel") {
            intelGpuProc.running = true
        }
    }
    
    function updateCpuTemp() {
        cpuTempProcess.running = true
    }

    function updateTopProcesses() {
        topProcessesProc.buffer = []
        topProcessesProc.running = true
    }
    
    function formatBytes(bytes) {
        const gb = bytes / (1024 ** 3)
        if (gb >= 1) return { value: gb, unit: "GB" }
        const mb = bytes / (1024 ** 2)
        if (mb >= 1) return { value: mb, unit: "MB" }
        const kb = bytes / 1024
        return { value: kb, unit: "KB" }
    }
    
    // CPU usage calculation
    Process {
        id: cpuProcess
        command: ["/bin/sh", "-c", "cat /proc/stat | grep '^cpu '"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 5) {
                    const user = parseInt(parts[1])
                    const nice = parseInt(parts[2])
                    const system = parseInt(parts[3])
                    const idle = parseInt(parts[4])
                    const total = user + nice + system + idle
                    
                    if (lastCpuTotal > 0) {
                        const totalDiff = total - lastCpuTotal
                        const idleDiff = idle - lastCpuIdle
                        if (totalDiff > 0) {
                            cpuPerc = 1 - (idleDiff / totalDiff)
                        }
                    }
                    
                    lastCpuIdle = idle
                    lastCpuTotal = total
                }
            }
        }
    }
    
    // Memory usage
    Process {
        id: memProcess
        command: ["/bin/sh", "-c", "free -b | grep Mem"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    memTotal = parseInt(parts[1])
                    memUsed = parseInt(parts[2])
                }
            }
        }
    }
    
    // Disk usage
    Process {
        id: diskProcess
        command: ["/bin/sh", "-c", "df -B1 / | tail -1"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 3) {
                    diskTotal = parseInt(parts[1])
                    diskUsed = parseInt(parts[2])
                }
            }
        }
    }
    
    // Network speed monitoring (all interfaces combined)
    Process {
        id: networkProcess
        command: ["/bin/sh", "-c", "cat /proc/net/dev | tail -n +3 | awk '{rx+=$2; tx+=$10} END {print rx\" \"tx}'"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 2) {
                    const rxBytes = parseInt(parts[0])
                    const txBytes = parseInt(parts[1])
                    const currentTime = Date.now() / 1000  // seconds

                    if (lastNetTime > 0) {
                        const timeDiff = currentTime - lastNetTime
                        if (timeDiff > 0) {
                            downloadSpeed = (rxBytes - lastRxBytes) / timeDiff
                            uploadSpeed = (txBytes - lastTxBytes) / timeDiff

                            // Add to history (keep last 30 points = 60 seconds)
                            // Must assign a new array so QML bindings detect the change
                            const next = networkHistory.concat({download: downloadSpeed, upload: uploadSpeed})
                            networkHistory = next.length > 30 ? next.slice(1) : next
                        }
                    }

                    lastRxBytes = rxBytes
                    lastTxBytes = txBytes
                    lastNetTime = currentTime
                }
            }
        }
    }
    
    // GPU Detection
    Process {
        id: gpuDetectProc
        command: ["/bin/sh", "-c", "if command -v nvidia-smi >/dev/null 2>&1; then echo 'nvidia'; elif command -v radeontop >/dev/null 2>&1; then echo 'amd'; elif [ -d /sys/class/drm/card0/device/drm/card0 ]; then echo 'intel'; else echo 'none'; fi"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const type = data.trim()
                gpuType = type
                hasGpu = type !== "none"
                QsServices.Logger.debug("SystemUsage", `GPU detected: ${type}`)
                if (hasGpu) {
                    updateGpu()
                }
            }
        }
    }
    
    // NVIDIA GPU monitoring
    Process {
        id: nvidiaGpuProc
        command: ["/bin/sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(',').map(x => x.trim())
                if (parts.length >= 4) {
                    gpuUsage = parseFloat(parts[0])
                    gpuTemp = parseFloat(parts[1])
                    gpuMemUsed = parseFloat(parts[2])
                    gpuMemTotal = parseFloat(parts[3])
                }
            }
        }
    }
    
    // AMD GPU monitoring (using radeontop)
    Process {
        id: amdGpuProc
        command: ["/bin/sh", "-c", "radeontop -d - -l 1 2>/dev/null | grep -oP 'gpu \\K[0-9.]+' | head -1"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                gpuUsage = parseFloat(data.trim())
                // AMD temp from hwmon
                amdTempProc.running = true
            }
        }
    }
    
    Process {
        id: amdTempProc
        command: ["/bin/sh", "-c", "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                gpuTemp = parseInt(data.trim()) / 1000  // millidegrees to degrees
            }
        }
    }
    
    // Intel GPU monitoring (basic via sysfs)
    Process {
        id: intelGpuProc
        command: ["/bin/sh", "-c", "cat /sys/class/drm/card0/device/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo '0'"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                // Intel doesn't expose usage easily, estimate from frequency
                const freq = parseInt(data.trim())
                gpuUsage = freq > 0 ? Math.min(100, freq / 15) : 0  // rough estimate
            }
        }
    }
    
    // Top CPU-consuming processes
    Process {
        id: topProcessesProc
        property var buffer: []
        command: ["/bin/sh", "-c", "ps aux --sort=-%cpu | awk 'NR>1{n=$11; gsub(\".*/\",\"\",n); if(n!=\"ps\"&&n!=\"sh\"&&n!=\"awk\"&&n!=\"grep\"&&n!=\"head\"&&n!=\"tail\") print n\"|\"$3\"|\"$2}' | head -5"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split('|')
                if (parts.length >= 2)
                    topProcessesProc.buffer = topProcessesProc.buffer.concat([{
                        name: parts[0] || "Unknown",
                        cpu: parseFloat(parts[1]) || 0,
                        pid: parseInt(parts[2]) || 0
                    }])
            }
        }
        onExited: { root.topProcesses = topProcessesProc.buffer; topProcessesProc.buffer = [] }
    }
    
    Process {
        id: cpuTempProcess
        command: ["/bin/sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo '0'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                cpuTemp = parseInt(data.trim()) / 1000
            }
        }
    }

    // Update timer - optimized with staggered updates
    // Only runs when active (controlled by consumer visibility)
    Timer {
        id: updateTimer
        interval: 500  // Base interval
        repeat: true
        running: root.active  // Pause when no consumer is visible
        triggeredOnStart: true  // Immediate first read
        
        property int tickCount: 0
        
        onTriggered: {
            tickCount++
            
            // Update CPU, Memory, Network every tick (2s)
            updateCpu()
            updateCpuTemp()
            updateMemory()
            updateNetwork()
            
            // Update Disk less frequently (every 10s)
            if (tickCount % 5 === 0) {
                updateDisk()
            }
            
            // Update GPU moderately (every 4s)
            if (tickCount % 2 === 0) {
                updateGpu()
            }
            
            // Update top processes less frequently (every 6s)
            if (tickCount % 3 === 0) {
                updateTopProcesses()
            }
        }
    }
}
