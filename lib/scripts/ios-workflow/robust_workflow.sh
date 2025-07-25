#!/bin/bash
# Robust iOS workflow with fallback options

set -euo pipefail

# Source environment loader
source "$(dirname "$0")/env_loader.sh"

# Load environment variables
set_defaults

# Main workflow with fallback
main() {
    echo "🚀 Starting Robust iOS Workflow"
    
    # Try the main workflow first
    if bash "$(dirname "$0")/new_ios_workflow.sh"; then
        echo "✅ Main workflow completed successfully"
        return 0
    else
        echo "⚠️ Main workflow failed, trying fallback..."
        
        # Try fallback workflow
        if bash "$(dirname "$0")/fallback_workflow.sh"; then
            echo "✅ Fallback workflow completed successfully"
            return 0
        else
            echo "❌ Both main and fallback workflows failed"
            return 1
        fi
    fi
}

# Execute main function
main "$@"
