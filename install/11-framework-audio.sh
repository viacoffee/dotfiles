#!/bin/bash

step "Checking Framework audio hardware"

framework_dmi_path=${FRAMEWORK_DMI_PATH:-/sys/class/dmi/id}
framework_audio_modprobe_dir=${FRAMEWORK_AUDIO_MODPROBE_DIR:-/etc/modprobe.d}
framework_audio_quirk_source="$DOTFILES_INSTALL_DEFAULTS_PATH/modprobe/framework-13-ai-300-audio.conf"
framework_audio_quirk_target="$framework_audio_modprobe_dir/framework-13-ai-300-audio.conf"

system_vendor=$(cat "$framework_dmi_path/sys_vendor" 2>/dev/null || true)
product_name=$(cat "$framework_dmi_path/product_name" 2>/dev/null || true)

if [[ $system_vendor == Framework &&
      $product_name == "Laptop 13 (AMD Ryzen AI 300 Series)" ]]; then
  run_logged "Disabling the phantom Framework ACP microphone" \
    sudo install -Dm644 "$framework_audio_quirk_source" "$framework_audio_quirk_target"
  success "Configured the working Realtek internal microphone path"
elif sudo test -e "$framework_audio_quirk_target"; then
  run_logged "Removing an inapplicable Framework audio quirk" \
    sudo rm -f "$framework_audio_quirk_target"
else
  section_note "Framework Laptop 13 AMD Ryzen AI 300 audio quirk not needed"
fi
