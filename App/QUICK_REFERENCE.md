# 🚀 Quick Reference Card
## Robotic Gripper Control Application v1.0.0

> **Print this page for quick reference!**

---

## 📱 5 Main Screens

| Icon | Screen | What It Does |
|:----:|--------|--------------|
| 📊 | **Dashboard** | Real-time status & metrics |
| 🎮 | **Control** | Manual gripper control |
| 🤖 | **Teaching** | Create automated patterns |
| ⚡ | **Auto-Run** | Execute saved patterns |
| ⚙️ | **Settings** | Configure app |

---

## ⚡ Quick Actions

### Dashboard
- 👀 **Monitor** → Real-time data updates every second
- 📈 **Analytics** → View confidence chart

### Control
1. ✅ Check **Safety Interlock** is ON (green)
2. ✅ Check **System Power** is ON
3. 🎚️ Adjust **Gripper Angle** (0-180°)
4. 💪 Set **Max Force** (0-10N)

### Teaching Mode
1. ➕ **CREATE NEW PATTERN**
2. 📝 Enter name & description
3. 🟠 **RECORD GRIP** → Close gripper
4. 🔵 **RECORD RELEASE** → Open gripper  
5. 🟣 **ADD WAIT** → Pause
6. ▶️ **PLAY SEQUENCE** → Test
7. 💾 **SAVE PATTERN** → Store

### Auto-Run
1. 📋 **Select Pattern** from dropdown
2. ▶️ **RUN PATTERN** to execute
3. 📥 **Download CSV** for logs

---

## 🎯 Common Tasks

### Create Basic Pick & Place
```
1. CREATE NEW PATTERN: "Pick and Place"
2. RECORD RELEASE: 90° (open)
3. ADD WAIT: 1.0s
4. RECORD GRIP: 30° (close)
5. ADD WAIT: 2.0s
6. RECORD RELEASE: 90° (open)
7. SAVE PATTERN
```

### Change Language
```
Settings → Language → Select (EN/TH) → Done
```

### Change Backend URL
```
Settings → Backend URL → Enter URL → Save → Restart
```

### Sync Patterns
```
Teaching → 🔄 Sync button → Wait → Done
```

### Export Logs
```
Auto-Run → Log History → 📥 Download → Open CSV
```

---

## 🔧 Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Cannot connect | Check Backend running on port 5000 |
| Cannot control | Check Safety Interlock is ON |
| Pattern not saved | Press SAVE PATTERN button |
| App crashes | Clear app data & restart |
| Data not updating | Check connection status |

---

## 💡 Pro Tips

### Teaching Mode
- 🎯 Test patterns with **PLAY SEQUENCE** before saving
- 🔄 Use **Move Up/Down** to reorder steps
- 📋 Use **CLEAR ALL** to start over
- 🔁 Add multiple WAIT steps for complex timing

### Control
- ⚠️ Always enable Safety Interlock first
- 📐 Use small angle changes for precision
- 💪 Set lower force for fragile objects
- 🛑 Use Power button as emergency stop

### Auto-Run
- 📊 Check pattern details before running
- 📁 Download logs regularly for analysis
- 🗑️ Delete old logs to save space
- 🔄 Re-run patterns anytime

---

## 📞 Help Resources

| Need | Check |
|------|-------|
| Full Manual | [USER_MANUAL.md](USER_MANUAL.md) |
| Installation | [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) |
| API Reference | [API_DOCUMENTATION.md](API_DOCUMENTATION.md) |
| All Docs | [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) |

---

## 🌍 Language Options

- 🇬🇧 **English** - Full support
- 🇹🇭 **ภาษาไทย** - รองรับเต็มรูปแบบ

Change in Settings anytime!

---

## 📊 Limits & Ranges

| Parameter | Min | Max | Unit | Default |
|-----------|-----|-----|------|---------|
| Gripper Angle | 0 | 180 | degrees | 90 |
| Max Force | 0 | 10 | Newtons | 10 |
| Wait Duration | 0.1 | 60 | seconds | 1.0 |
| Pattern Steps | 1 | 100 | steps | - |

---

## 🎨 Color Coding

| Color | Action | Icon |
|-------|--------|------|
| 🟠 Orange | Grip | Closing |
| 🔵 Blue | Release | Opening |
| 🟣 Purple | Wait | Clock |
| 🟢 Green | Running | Playing |
| 🔴 Red | Error/Off | Warning |

---

## ⌨️ Keyboard Shortcuts

*Desktop versions only*

| Key | Action |
|-----|--------|
| `Ctrl+S` | Save Pattern |
| `Ctrl+N` | New Pattern |
| `Ctrl+R` | Refresh/Sync |
| `Space` | Play/Pause |
| `Esc` | Stop/Cancel |

---

## 📦 Version Info

- **Version**: 1.0.0
- **Build**: 1
- **Released**: January 2026
- **Platform**: Cross-platform

---

## 🔒 Safety Checklist

Before using Control:
- [ ] Safety Interlock enabled (green)
- [ ] System Power on
- [ ] Backend connected (or offline mode OK)
- [ ] Force limit set appropriately
- [ ] Area clear of obstacles

Before running patterns:
- [ ] Pattern tested
- [ ] Steps verified
- [ ] Force limits checked
- [ ] Workspace clear

---

## 📝 Quick Notes

**Backend Default URL**: `http://localhost:5000`

**Database Location** (mobile):
- Android: `/data/data/com.example.../databases/`
- iOS: App Documents folder

**CSV Export Location**:
- Android/iOS: Downloads folder
- Desktop: Downloads folder

---

## 🆘 Emergency Actions

### App Frozen
```
1. Force close app
2. Restart device if needed
3. Reopen app
```

### Backend Lost
```
1. Check simulation.py running
2. Restart backend if needed
3. Try "Continue Offline" in app
```

### Cannot Save
```
1. Check storage space
2. Clear app cache
3. Settings → Clear Database → Restart
```

---

## 🎯 Getting Started (5 Minutes)

1. **Install** → Follow [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
2. **Launch** → Wait for connection or go offline
3. **Explore** → Tap each screen in bottom nav
4. **Try Control** → Enable Safety → Move slider
5. **Create Pattern** → Teaching → Create → Save
6. **Run It** → Auto-Run → Select → Execute

---

## 📱 Contact & Support

**Documentation**: See [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)  
**Full Manual**: See [USER_MANUAL.md](USER_MANUAL.md)  
**FAQ**: USER_MANUAL.md Section 5

---

**Keep this card handy for quick reference! 📌**

🤖 **Robotic Gripper Control v1.0.0** | ⚡ Built with Flutter
