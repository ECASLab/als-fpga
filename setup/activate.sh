#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# als-fpga environment activation
#
# Usage:
#   source setup/activate.sh
#
# Must be SOURCED, not executed — it needs to activate the
# conda environment in your CURRENT shell.
# ---------------------------------------------------------------------------

# Check if the script is being sourced or executed
(return 0 2>/dev/null) && _als_sourced=1 || _als_sourced=0
if [ "$_als_sourced" -eq 0 ]; then
    echo "Error: this script must be sourced, not executed." >&2
    echo "Run:   source setup/activate.sh" >&2
    exit 1
fi
unset _als_sourced

# Colors for output (only if stdout is a terminal)
if [ -t 1 ]; then
    _c_reset=$'\033[0m'; _c_bold=$'\033[1m'; _c_dim=$'\033[2m'
    _c_green=$'\033[32m'; _c_yellow=$'\033[33m'; _c_red=$'\033[31m'; _c_cyan=$'\033[36m'
else
    _c_reset=''; _c_bold=''; _c_dim=''; _c_green=''; _c_yellow=''; _c_red=''; _c_cyan=''
fi

_als_ok()   { printf "  %s✔%s %s\n" "$_c_green" "$_c_reset" "$1"; }
_als_warn() { printf "  %s⚠%s %s\n" "$_c_yellow" "$_c_reset" "$1"; }
_als_err()  { printf "  %s✘%s %s\n" "$_c_red" "$_c_reset" "$1"; }
_als_step() { printf "\n%s%s▸ %s%s\n" "$_c_bold" "$_c_cyan" "$1" "$_c_reset"; }

# Determine the root of the repository
if command -v realpath >/dev/null 2>&1; then
    _als_script_path="$(realpath -- "${BASH_SOURCE[0]}")"
else
    _als_script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
fi
ALS_FPGA_ROOT="$(dirname -- "$(dirname -- "$_als_script_path")")"
unset _als_script_path

printf "\n%s%s┌──────────────────────────────────────────────┐%s\n" "$_c_bold" "$_c_cyan" "$_c_reset"
printf "%s%s│%s   als-fpga  ·  environment setup             %s%s│%s\n" "$_c_bold" "$_c_cyan" "$_c_reset" "$_c_bold" "$_c_cyan" "$_c_reset"
printf "%s%s└──────────────────────────────────────────────┘%s\n" "$_c_bold" "$_c_cyan" "$_c_reset"

# Set default values for environment variables if not already set
export F4PGA_INSTALL_DIR="${F4PGA_INSTALL_DIR:-$HOME/opt/f4pga-als}"
export FPGA_FAM="${FPGA_FAM:-xc7}"
_als_vtr_ace_link="$HOME/.local/bin/vtr-ace"

# Activate the conda environment for F4PGA
_als_step "F4PGA environment"

_als_conda_sh="$F4PGA_INSTALL_DIR/$FPGA_FAM/conda/etc/profile.d/conda.sh"
if [ ! -f "$_als_conda_sh" ]; then
    _als_err "conda.sh not found at: $_als_conda_sh"
    _als_warn "Check F4PGA_INSTALL_DIR / FPGA_FAM, or run the base install (README.md, step 2)"
    unset _als_conda_sh _als_vtr_ace_link
    unset -f _als_ok _als_warn _als_err _als_step
    return 1
fi
# shellcheck source=/dev/null
source "$_als_conda_sh"
unset _als_conda_sh

if ! conda activate "$FPGA_FAM" 2>/dev/null; then
    _als_err "Failed to activate conda environment '$FPGA_FAM'"
    unset _als_vtr_ace_link
    unset -f _als_ok _als_warn _als_err _als_step
    return 1
fi
_als_ok "conda env '${FPGA_FAM}' active"
_als_ok "  $F4PGA_INSTALL_DIR"

# Check that the f4pga package is importable in this environment
_als_step "F4PGA package"

_als_f4pga_loc="$(python -c 'import f4pga; print(list(f4pga.__path__)[0])' 2>/dev/null)"
if [ -z "$_als_f4pga_loc" ]; then
    _als_err "Could not import f4pga in this environment"
elif [[ "$_als_f4pga_loc" == "$ALS_FPGA_ROOT"* ]]; then
    _als_ok "modified fork active (editable install)"
    _als_ok "  $_als_f4pga_loc"
else
    _als_warn "f4pga resolves outside this repo:"
    _als_warn "  $_als_f4pga_loc"
    _als_warn "run: pip install -e tools/f4pga/f4pga"
fi
unset _als_f4pga_loc

# Check that VTR/ace is available
_als_step "VTR / ace"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

if command -v vtr-ace >/dev/null 2>&1; then
    _als_ok "vtr-ace available: $(command -v vtr-ace)"
elif [ -e "$ALS_FPGA_ROOT/tools/vtr/build/ace2/ace" ]; then
    _als_warn "vtr-ace not linked yet, run:"
    _als_warn "  ln -sf \"$ALS_FPGA_ROOT/tools/vtr/build/ace2/ace\" \"$_als_vtr_ace_link\""
else
    _als_warn "VTR/ace not built yet (see README.md)"
fi
unset _als_vtr_ace_link

# Final summary
printf "\n%s%s┌──────────────────────────────────────────────┐%s\n" "$_c_bold" "$_c_green" "$_c_reset"
printf "%s%s│%s  ✔ Environment ready                         %s%s│%s\n" "$_c_bold" "$_c_green" "$_c_reset" "$_c_bold" "$_c_green" "$_c_reset"
printf "%s%s└──────────────────────────────────────────────┘%s\n" "$_c_bold" "$_c_green" "$_c_reset"
printf "  %sconda env%s     %s\n" "$_c_dim" "$_c_reset" "$FPGA_FAM"
printf "  %srepo root%s     %s\n" "$_c_dim" "$_c_reset" "$ALS_FPGA_ROOT"
printf "  %spython%s        %s\n" "$_c_dim" "$_c_reset" "$(command -v python)"



unset -f _als_ok _als_warn _als_err _als_step