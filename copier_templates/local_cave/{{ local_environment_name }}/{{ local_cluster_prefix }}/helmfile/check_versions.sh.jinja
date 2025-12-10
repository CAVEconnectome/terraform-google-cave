#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking Helm chart versions..."
echo "=================================="

# Ensure cave repository is added and updated
echo "📦 Setting up cave helm repository..."
helm repo add cave https://caveconnectome.github.io/cave-helm-charts/ 2>/dev/null || true

echo "📦 Updating helm repositories (this may take a moment)..."
helm repo update

# Verify cave repo is accessible
echo "🔍 Verifying cave repository access..."
if ! helm search repo cave/ --max-col-width=0 > /dev/null 2>&1; then
    echo "❌ Error: Cannot access cave repository. Please check your connection."
    exit 1
fi

echo "✅ Repository cache updated successfully"
echo ""
echo "📋 Available charts in cave repository:"
helm search repo cave/ --max-col-width=0 | head -10
echo ""

# Parse current versions dynamically from helmfile.yaml
helmfile_path="helmfile.yaml"

if [ ! -f "$helmfile_path" ]; then
    echo "❌ Error: helmfile.yaml not found in current directory"
    exit 1
fi

echo "📄 Parsing versions from $helmfile_path..."

# Create temporary files to store chart names and versions (compatible with older bash)
charts_file=$(mktemp)
versions_file=$(mktemp)

# Parse helmfile.yaml to extract chart names and versions
current_chart=""
while IFS= read -r line; do
    # Look for chart: lines
    if [[ $line =~ chart:[[:space:]]*cave/([^[:space:]]+) ]]; then
        chart_name=$(echo "$line" | sed -n 's/.*chart:[[:space:]]*cave\/\([^[:space:]]*\).*/\1/p')
        current_chart="$chart_name"
    fi
    
    # Look for version: lines that follow chart: lines
    if [[ $line =~ version:[[:space:]]*([^[:space:]]+) ]] && [ ! -z "$current_chart" ]; then
        version=$(echo "$line" | sed -n 's/.*version:[[:space:]]*\([^[:space:]]*\).*/\1/p')
        echo "$current_chart" >> "$charts_file"
        echo "$version" >> "$versions_file"
        current_chart=""
    fi
done < "$helmfile_path"

# Check if we found any versions
chart_count=$(wc -l < "$charts_file" | tr -d ' ')
if [ "$chart_count" -eq 0 ]; then
    echo "❌ Error: No chart versions found in helmfile.yaml"
    rm -f "$charts_file" "$versions_file"
    exit 1
fi

echo ""
printf "%-25s %-12s %-12s %s\n" "Chart" "Current" "Latest" "Status"
echo "=================================================================="

# Process each chart
line_num=1
while [ $line_num -le $chart_count ]; do
    chart=$(sed -n "${line_num}p" "$charts_file")
    current=$(sed -n "${line_num}p" "$versions_file")
    full_chart_name="cave/$chart"
    
    # Get latest version with better error handling and debugging
    search_result=$(helm search repo "$full_chart_name" --max-col-width=0 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$search_result" ]; then
        printf "%-25s %-12s %-12s ${RED}❌ Not found${NC}\n" "$chart" "$current" "N/A"
        line_num=$((line_num + 1))
        continue
    fi
    
    # Extract version using awk (skip header line)
    latest=$(echo "$search_result" | awk 'NR==2 {print $2}')
    
    # Debug: show what we found if version parsing fails
    if [ -z "$latest" ] || [ "$latest" = "CHART" ]; then
        echo "Debug: Search result for $full_chart_name:"
        echo "$search_result" | head -3
        latest="PARSE_ERROR"
    fi
    
    if [ -z "$latest" ] || [ "$latest" = "CHART" ]; then
        printf "%-25s %-12s %-12s ${RED}❌ Parse error${NC}\n" "$chart" "$current" "N/A"
        line_num=$((line_num + 1))
        continue
    fi
    
    # Simple string comparison
    if [ "$current" = "$latest" ]; then
        printf "%-25s %-12s %-12s ${GREEN}✅ Up to date${NC}\n" "$chart" "$current" "$latest"
    else
        printf "%-25s %-12s %-12s ${YELLOW}⬆️  Update available${NC}\n" "$chart" "$current" "$latest"
    fi
    
    line_num=$((line_num + 1))
done

# Cleanup
rm -f "$charts_file" "$versions_file"

echo ""
echo "💡 To update a chart version:"
echo "   1. Edit helmfile.yaml and change the version number"
echo "   2. Run: helmfile diff (to preview changes)"
echo "   3. Run: helmfile apply (to deploy changes)"