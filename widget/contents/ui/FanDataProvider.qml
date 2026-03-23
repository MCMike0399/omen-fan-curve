import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: provider

    property int fan1Rpm: 0
    property int fan2Rpm: 0
    property string fanMode: "auto"
    property real cpuTemp: 0
    property real gpuTemp: 0

    // Discovery script: find hwmon paths by name, then read values
    readonly property string script: "
        HP=$(grep -rl '^hp$' /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname 2>/dev/null);
        CT=$(grep -rl '^coretemp$' /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname 2>/dev/null);
        [ -n \"$HP\" ] && cat $HP/fan1_input $HP/fan2_input $HP/pwm1_enable 2>/dev/null || echo -e '0\\n0\\n2';
        nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo '0';
        [ -n \"$CT\" ] && cat $CT/temp1_input 2>/dev/null || echo '0'
    "

    Plasma5Support.DataSource {
        id: dataSource
        engine: "executable"
        connectedSources: [provider.script]
        interval: 2000

        onNewData: function(source, data) {
            var lines = data.stdout.split("\n").filter(function(l) { return l.trim() !== ""; });
            if (lines.length >= 3) {
                provider.fan1Rpm = parseInt(lines[0]) || 0;
                provider.fan2Rpm = parseInt(lines[1]) || 0;
                var mode = parseInt(lines[2]) || 2;
                provider.fanMode = mode === 0 ? "max" : mode === 1 ? "manual" : "auto";
            }
            if (lines.length >= 4) {
                provider.gpuTemp = parseFloat(lines[3]) || 0;
            }
            if (lines.length >= 5) {
                provider.cpuTemp = (parseInt(lines[4]) || 0) / 1000;
            }
        }
    }
}
