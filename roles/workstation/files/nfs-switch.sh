#!/bin/bash
# Script to switch between NFS and local fallback directories
# Usage: nfs-switch.sh [online|offline|status]

USER=$(whoami)
MODE=${1:-status}

# Define directory mappings
declare -A DIRECTORIES=(
    ["documents"]="/mnt/truenas/${USER}-documents"
    ["downloads"]="/mnt/truenas/${USER}-downloads"
)

case $MODE in
    "online")
        echo "Switching to NFS (online) mode..."
        for dir in "${!DIRECTORIES[@]}"; do
            local_dir="/home/${USER}/${dir}"
            nfs_target="${DIRECTORIES[$dir]}"
            fallback_dir="/home/${USER}/.local-${dir}"
            
            if [ -d "$nfs_target" ]; then
                # Remove existing symlink/directory
                rm -rf "$local_dir"
                # Create symlink to NFS
                ln -sf "$nfs_target" "$local_dir"
                echo "✅ $dir -> NFS ($nfs_target)"
            else
                echo "❌ NFS target $nfs_target not available for $dir"
            fi
        done
        ;;
        
    "offline")
        echo "Switching to local (offline) mode..."
        for dir in "${!DIRECTORIES[@]}"; do
            local_dir="/home/${USER}/${dir}"
            fallback_dir="/home/${USER}/.local-${dir}"
            
            # Create fallback directory if it doesn't exist
            mkdir -p "$fallback_dir"
            # Remove existing symlink
            rm -rf "$local_dir"
            # Create symlink to local fallback
            ln -sf "$fallback_dir" "$local_dir"
            echo "✅ $dir -> Local ($fallback_dir)"
        done
        ;;
        
    "status")
        echo "Current directory status for user $USER:"
        echo "========================================="
        for dir in "${!DIRECTORIES[@]}"; do
            local_dir="/home/${USER}/${dir}"
            nfs_target="${DIRECTORIES[$dir]}"
            fallback_dir="/home/${USER}/.local-${dir}"
            
            if [ -L "$local_dir" ]; then
                target=$(readlink "$local_dir")
                if [ "$target" == "$nfs_target" ]; then
                    if [ -d "$nfs_target" ]; then
                        echo "📁 $dir: NFS (online) -> $target"
                    else
                        echo "⚠️  $dir: NFS (broken link) -> $target"
                    fi
                elif [ "$target" == "$fallback_dir" ]; then
                    echo "💾 $dir: Local (offline) -> $target"
                else
                    echo "❓ $dir: Unknown -> $target"
                fi
            elif [ -d "$local_dir" ]; then
                echo "📂 $dir: Directory (not symlink)"
            else
                echo "❌ $dir: Missing"
            fi
        done
        echo ""
        echo "NFS mount status:"
        echo "=================="
        for dir in "${!DIRECTORIES[@]}"; do
            nfs_target="${DIRECTORIES[$dir]}"
            if mountpoint -q "$nfs_target" 2>/dev/null; then
                echo "✅ $nfs_target: Mounted"
            else
                echo "❌ $nfs_target: Not mounted"
            fi
        done
        ;;
        
    *)
        echo "Usage: $0 [online|offline|status]"
        echo "  online  - Switch to NFS directories"
        echo "  offline - Switch to local fallback directories"  
        echo "  status  - Show current status"
        exit 1
        ;;
esac
