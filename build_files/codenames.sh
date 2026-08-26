#!/bin/bash
# CalOS release codenames, keyed by MINOR version (matching git tags vX.Y.Z).
# Example scheme: v1.1.x = "CalOS Huron", v1.2.x = "CalOS Superior", ...
# Add a new line here when starting a new minor release cycle.
#
# Usage: source build_files/codenames.sh && calos_codename "2"  # -> Superior
calos_codename() {
    case "${1:-}" in
        1) echo "Huron" ;;
        2) echo "Superior" ;;
        3) echo "Eerie" ;;
        *) echo "" ;;
    esac
}
