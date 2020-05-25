#!/bin/bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
readonly REPO_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"

# Plugins that deliberately use their own analysis_options.yaml.
#
# This list should only be deleted from, never added to. This only exists
# because we adopted stricter analysis rules recently and needed to exclude
# already failing packages to start linting the repo as a whole.
#
# TODO(mklim): Remove everything from this list. https://github.com/flutter/flutter/issues/45440
CUSTOM_ANALYSIS_PLUGINS=(
  "cloud_firestore"
  "cloud_functions"
  "firebase_analytics"
  "firebase_auth"
  "firebase_core"
  "firebase_crashlytics"
  "firebase_database"
  "firebase_dynamic_links"
  "firebase_in_app_messaging"
  "firebase_messaging"
  "firebase_ml_vision"
  "firebase_performance"
  "firebase_remote_config"
  "firebase_storage"
)
# Comma-separated string of the list above
readonly CUSTOM_FLAG=$(IFS=, ; echo "${CUSTOM_ANALYSIS_PLUGINS[*]}")
# Set some default actions if run without arguments.
ACTIONS=("$@")
if [[ "${#ACTIONS[@]}" == 0 ]]; then
  ACTIONS=("analyze" "--custom-analysis" "$CUSTOM_FLAG" "test" "java-test")
elif [[ "${ACTIONS[@]}" == "analyze" ]]; then
  ACTIONS=("analyze" "--custom-analysis" "$CUSTOM_FLAG")
fi

BRANCH_NAME="${BRANCH_NAME:-"$(git rev-parse --abbrev-ref HEAD)"}"
if [[ "${BRANCH_NAME}" == "master" ]]; then
  echo "Running for all packages"
  (cd "$REPO_DIR" && pub global run flutter_plugin_tools "${ACTIONS[@]}" $PLUGIN_SHARDING)
else
  # Sets CHANGED_PACKAGES
  check_changed_packages

  if [[ "$CHANGED_PACKAGES" == "" ]]; then
    echo "No changes detected in packages."
  else
    (cd "$REPO_DIR" && pub global run flutter_plugin_tools "${ACTIONS[@]}" --plugins="$CHANGED_PACKAGES" $PLUGIN_SHARDING)
    echo "Running version check for changed packages"
    # TODO(salakar): commenting out version check - will be replaced with auto versioning through melos
    # (cd "$REPO_DIR" && pub global run flutter_plugin_tools version-check --base_sha="$(get_branch_base_sha)")
  fi
fi
