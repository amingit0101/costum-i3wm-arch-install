#!/bin/bash

# Function to show page 1
show_page1() {
  zenity --info \
    --title="Welcome to Your Custom Arch ISO" \
    --width=650 \
    --height=450 \
    --ok-label="Next →" \
    --extra-button="Skip" \
    --text="<b>🚀 Welcome to Your Custom Arch ISO!</b>\n\n\
<b>📋 Workspace Navigation:</b>\n\
    • Super+1-0     → Switch to workspace\n\
    • Super+Shift+1-0 → Move window to workspace\n\
    • Super+Tab     → Next workspace\n\
    • Super+Shift+Tab → Previous workspace\n\n\
<b>⌨️  Window Management:</b>\n\
    • Super+j/k/l/; focus down/up/left/right window  (alacritty)\n\
    • Super+Enter   → Terminal (alacritty)\n\
    • Super+Q       → Kill window\n\
    • Super+D       → Application launcher (rofi)\n\
    • Super+T       → Window switcher (rofi)\n\
    • Super+F       → Toggle fullscreen\n\
    • Super+R       → Resize mode\n\
    • Super+Space   → Toggle focus mode\n\
    • Super+Shift+Space → Toggle floating\n\n\
<b>🎨 Window Layouts:</b>\n\
    • Super+S       → Split horizontal\n\
    • Super+V       → Split vertical\n\
    • Super+Y       → Stacking layout\n\
    • Super+U       → Tabbed layout\n\
    • Super+I       → Toggle split"
}

# Function to show page 2
show_page2() {
  zenity --info \
    --title="Welcome to Your Custom Arch ISO" \
    --width=650 \
    --height=450 \
    --ok-label="Finish" \
    --extra-button="← Back" \
    --text="<b>🚀 Welcome to Your Custom Arch ISO!</b>\n\n\
<b>📌 Application Shortcuts:</b>\n\
    • Super+W       → Firefox\n\
    • Super+N       → Ranger (file manager)\n\
    • Super+M       → Htop (system monitor)\n\
    • Super+Shift+M → Pavucontrol (audio)\n\
    • Super+Shift+E → Power menu\n\
    • Print         → Screenshot (spectacle)\n\n\
<b>🔊 Media Keys:</b>\n\
    • Volume Up/Down → Adjust volume\n\
    • Mute          → Toggle mute\n\
    • Play/Pause    → Media control\n\n\
<b>🛠️  Tips:</b>\n\
    • Polybar shows system info (CPU, RAM, Disk, Network)\n\
    • Nord color theme for a clean look\n\
    • Picom compositor for smooth visuals\n\
    • Press Super+C to edit i3 config\n\
    • Press Super+Shift+I to open Installer\n\
    • Press Super+Shift+C to reload config\n\n\
<b>📖 Need more help?</b>\n\
    • Check ~/.config/i3/config for all settings\n\
    • Arch Wiki: https://wiki.archlinux.org"
}

# Main loop - show page 1 first
while true; do
  # Show page 1
  page1_result=$(show_page1)
  exit_code=$?

  # Check which button was clicked
  if [ $exit_code -eq 0 ]; then
    # "Next" clicked - show page 2
    while true; do
      page2_result=$(show_page2)
      exit_code2=$?

      if [ $exit_code2 -eq 0 ]; then
        # "Finish" clicked - exit welcome
        break 2
      elif [ "$page2_result" = "← Back" ]; then
        # "Back" clicked - go back to page 1
        break
      else
        # "Skip" or close button - exit welcome
        exit 0
      fi
    done
  else
    # "Skip" or close button - exit welcome
    exit 0
  fi
done

# Ask if they want to see this again
if zenity --question \
  --title="Welcome Screen" \
  --text="Show this welcome screen on next boot?" \
  --width=400; then
  # User wants it to show again - do nothing
  :
else
  # User wants to disable it
  rm -f /root/.config/autostart/welcome.desktop 2>/dev/null
  rm -f /etc/xdg/autostart/welcome.desktop 2>/dev/null
  zenity --info \
    --title="Disabled" \
    --text="Welcome screen disabled.\nYou can re-enable it later by running:\n/usr/local/bin/welcome.sh"
fi
