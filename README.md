# omen-fan-curve

Temperature-based fan curve daemon for **HP Omen** laptops on Linux. Controls fan speed via the hp-wmi hwmon interface based on CPU and GPU temperatures.

## How It Works

```
CPU temp (coretemp) ─┐
                     ├─→ max(temps) ─→ curve lookup ─→ fan speed % ─→ hwmon pwm1
GPU temp (nvidia)   ─┘
```

The daemon reads CPU and GPU temperatures every 2 seconds, picks the higher value, looks up the target fan speed from a configurable curve with linear interpolation, and writes it to the hp-wmi hwmon interface. Hysteresis (default 2°C) prevents fan oscillation.

## Default Fan Curve

The curve is designed to reach max fan speed at **80°C**, with a safety override at 90°C:

```
Fan %
100 ┤                                          ●━━━━━━
    │                                        ╱
 75 ┤                                    ●╱
    │                                 ╱
 60 ┤                            ●╱
 50 ┤                       ●╱
 40 ┤                  ●╱
 35 ┤             ●╱
 30 ┤        ●╱
 25 ┤   ●╱
  0 ┤●━━
    └──┬────┬────┬────┬────┬────┬────┬────┬────┬──→ °C
      40   45   50   55   60   65   70   75   80
```

| Temperature | Fan Speed | Typical Scenario |
|-------------|-----------|-----------------|
| ≤ 40°C | Auto (EC) | Idle, fans may stop |
| 45°C | 25% | Light desktop use |
| 50°C | 30% | Web browsing |
| 55°C | 35% | Compiling, light GPU |
| 60°C | 40% | Normal gaming |
| 65°C | 50% | Active gaming |
| 70°C | 60% | Heavy gaming |
| 75°C | 75% | Sustained heavy load |
| 80°C | 100% | Maximum cooling |
| ≥ 90°C | 100% | Critical safety override |

Temperatures between curve points are linearly interpolated.

## Prerequisites

- **Patched hp-wmi kernel module** with manual fan speed support
  - See: [hp-omen-trascend-cachyos-patch](https://github.com/MCMike0399/hp-omen-trascend-cachyos-patch)
- Python 3.6+
- `nvidia-smi` (for GPU temp reading, optional)
- Tested on HP Omen Transcend 14 (board 8C58) with CachyOS

## Installation

```bash
git clone https://github.com/MCMike0399/omen-fan-curve.git
cd omen-fan-curve
sudo ./install.sh
sudo systemctl start omen-fan-curve
```

## Usage

```bash
# Start the daemon (as systemd service)
sudo systemctl start omen-fan-curve
sudo systemctl stop omen-fan-curve     # Restores auto fan control on stop

# Run interactively with verbose output
sudo omen-fan-curve run -v

# Check current status
omen-fan-curve status

# Manually set fan speed (0=auto, 1-100=percentage)
sudo omen-fan-curve set 60
sudo omen-fan-curve auto               # Restore automatic control

# Generate default config
sudo omen-fan-curve generate-config -o /etc/omen-fan-curve.json
```

## Configuration

Edit `/etc/omen-fan-curve.json`:

```json
{
  "curve": [
    {"temp": 40, "speed": 0},
    {"temp": 45, "speed": 25},
    {"temp": 50, "speed": 30},
    {"temp": 55, "speed": 35},
    {"temp": 60, "speed": 40},
    {"temp": 65, "speed": 50},
    {"temp": 70, "speed": 60},
    {"temp": 75, "speed": 75},
    {"temp": 80, "speed": 100}
  ],
  "hysteresis": 2,
  "interval": 2,
  "critical_temp": 90,
  "auto_below": 40
}
```

- **curve**: Array of `{temp, speed}` points. Speed is 0-100%.
- **hysteresis**: Temperature must drop by this many degrees before fans slow down (prevents oscillation).
- **interval**: Seconds between temperature checks.
- **critical_temp**: Override to 100% above this temperature regardless of curve.
- **auto_below**: Use EC automatic fan control below this temperature (fans can fully stop).

Restart the service after editing: `sudo systemctl restart omen-fan-curve`

## How Fan Control Works (Technical)

The patched hp-wmi kernel module exposes fan control via the standard Linux hwmon interface:

```
/sys/class/hwmon/hwmonX/
├── fan1_input      # Fan 1 RPM (read-only)
├── fan2_input      # Fan 2 RPM (read-only)
├── pwm1_enable     # 0=full, 1=manual, 2=auto
└── pwm1            # Duty cycle 0-255 (when pwm1_enable=1)
```

When `pwm1` is written, the driver converts the 0-255 value to a 0-100% percentage and sends it to the EC via **WMI query `0x2E`** (`HPWMI_FAN_SPEED_SET_QUERY`). The EC then sets both fans to the requested speed.

The `hp_wmi_get_fan_count_userdefine_trigger()` function is called before each speed change to keep the EC in user-defined mode (the EC has a 120-second timeout that reverts to automatic).

### Fan Speed Range (HP Omen Transcend 14)

| Percentage | Approximate RPM |
|-----------|----------------|
| 25% | ~3500 |
| 50% | ~4000 |
| 60% | ~4300 |
| 80% | ~4800 |
| 100% | ~5200 |

## Uninstall

```bash
sudo ./uninstall.sh
```

## License

MIT
