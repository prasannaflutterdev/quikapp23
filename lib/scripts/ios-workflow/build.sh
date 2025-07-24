#!/bin/bash
set -euo pipefail

# iOS Workflow Build Script (patched)
# Delegates to main_workflow.sh for full build, archive, and export with code signing

bash scripts/ios-workflow/main_workflow.sh 