#!/bin/bash
# Improved download function with better error handling

improved_download() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    if [ -z "$url" ]; then
        echo "No URL provided for $description, skipping"
        return 0
    fi
    
    echo "Downloading $description from: $url"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_path")"
    
    # Try multiple download methods with exponential backoff
    local max_retries=5
    local retry_count=0
    local base_delay=2
    
    while [ $retry_count -lt $max_retries ]; do
        local delay=$((base_delay * (2 ** retry_count)))
        
        # Method 1: Standard curl with longer timeout
        if curl -L -f -s --connect-timeout 60 --max-time 300 -o "$output_path" "$url" 2>/dev/null; then
            echo "✅ $description downloaded successfully"
            return 0
        fi
        
        # Method 2: Curl with custom user agent
        if curl -L -f -s --connect-timeout 60 --max-time 300 -o "$output_path" \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -H "Accept: */*" \
            -H "Accept-Language: en-US,en;q=0.9" \
            "$url" 2>/dev/null; then
            echo "✅ $description downloaded successfully (with custom headers)"
            return 0
        fi
        
        # Method 3: Try without redirect
        if curl -f -s --connect-timeout 60 --max-time 300 -o "$output_path" "$url" 2>/dev/null; then
            echo "✅ $description downloaded successfully (without redirect)"
            return 0
        fi
        
        # Method 4: Wget if available
        if command -v wget >/dev/null 2>&1; then
            if wget --timeout=60 --tries=3 --user-agent="Mozilla/5.0" -O "$output_path" "$url" 2>/dev/null; then
                echo "✅ $description downloaded successfully (with wget)"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        echo "⚠️ Download attempt $retry_count failed for $description"
        
        if [ $retry_count -lt $max_retries ]; then
            echo "Retrying in $delay seconds..."
            sleep $delay
        fi
    done
    
    echo "❌ Failed to download $description after $max_retries attempts"
    return 1
}
