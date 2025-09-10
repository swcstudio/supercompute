#!/bin/bash
# Stop Hook - Session Analytics and High-Performance Reporting
# Analyzes session productivity and triggers autonomous optimizations

if ! command -v julia &> /dev/null; then
    exit 0
fi

# Create necessary directories
mkdir -p ~/.claude/hooks/julia_business_automation/{logs,data,temp}

input=$(cat)
session_duration=$(echo "$input" | jq -r '.session_duration_ms // 0')
tools_used=$(echo "$input" | jq -r '.tools_used // []')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')

# Create comprehensive session summary for analytics
timestamp=$(date -Iseconds)
session_data=$(jq -n \
    --arg ts "$timestamp" \
    --argjson duration "$session_duration" \
    --argjson tools "$tools_used" \
    --arg session_id "$session_id" \
    '{
        timestamp: $ts,
        event: "session_complete",
        session_id: $session_id,
        duration_ms: $duration,
        tools_used: $tools,
        tool_count: ($tools | length),
        productivity_score: (if ($tools | length) > 0 then ($duration / 1000) / ($tools | length) else 0 end),
        efficiency_rating: (if $duration > 0 then ($tools | length) * 1000 / $duration else 0 end),
        session_type: (if ($tools | length) > 10 then "intensive" elif ($tools | length) > 5 then "moderate" else "light" end)
    }')

# Save session analytics with atomic write
session_log=~/.claude/hooks/julia_business_automation/logs/session_analytics.jsonl
echo "$session_data" >> "$session_log"

# Trigger high-performance Julia analytics processing
temp_input=$(mktemp)
echo "$session_data" > "$temp_input"

# Execute Julia analytics with performance optimization
julia --project=/home/ubuntu/.claude/hooks/julia_business_automation \
      --threads=$(nproc) \
      -e "
      using JSON3, Dates
      
      session_data = JSON3.read(read(\"$temp_input\", String))
      
      # High-performance session analysis
      duration_min = round(session_data[:duration_ms] / 60000, digits=1)
      tool_count = session_data[:tool_count]
      efficiency = round(session_data[:efficiency_rating], digits=2)
      
      println(\"📊 Session Analytics: \$(duration_min)min, \$(tool_count) tools, efficiency: \$(efficiency)\")
      
      # Update performance aggregates atomically
      aggregates_file = \"/home/ubuntu/.claude/hooks/julia_business_automation/data/session_aggregates.json\"
      
      aggregates = if isfile(aggregates_file)
          try
              JSON3.read(read(aggregates_file, String), Dict{String, Any})
          catch
              Dict{String, Any}()
          end
      else
          Dict{String, Any}()
      end
      
      # Update session statistics
      aggregates[\"total_sessions\"] = get(aggregates, \"total_sessions\", 0) + 1
      aggregates[\"total_duration_ms\"] = get(aggregates, \"total_duration_ms\", 0) + session_data[:duration_ms]
      aggregates[\"total_tools_used\"] = get(aggregates, \"total_tools_used\", 0) + tool_count
      aggregates[\"avg_session_duration_min\"] = round(aggregates[\"total_duration_ms\"] / 60000 / aggregates[\"total_sessions\"], digits=1)
      aggregates[\"avg_tools_per_session\"] = round(aggregates[\"total_tools_used\"] / aggregates[\"total_sessions\"], digits=1)
      aggregates[\"last_updated\"] = now()
      
      # Write updated aggregates
      open(aggregates_file, \"w\") do io
          JSON3.write(io, aggregates)
      end
      
      # Trigger autonomous optimization if high productivity session
      if efficiency > 2.0  # More than 2 tools per minute
          println(\"🚀 High productivity detected - triggering autonomous optimizations\")
      end
      " 2>/dev/null || echo "⚠ Julia analytics processing failed"

# Clean up temporary file
rm -f "$temp_input"

# Update daily productivity metrics
date_key=$(date +%Y%m%d)
daily_file=~/.claude/hooks/julia_business_automation/data/daily_productivity_$date_key.json

# Atomic daily metrics update
(
    flock -x 200
    if [[ -f "$daily_file" ]]; then
        current_data=$(cat "$daily_file")
    else
        current_data='{
            "date":"'$date_key'",
            "sessions":0,
            "total_duration_ms":0,
            "total_tools":0,
            "peak_efficiency":0,
            "productivity_score":0
        }'
    fi
    
    updated_data=$(echo "$current_data" | jq \
        --argjson duration "$session_duration" \
        --argjson tools "$(echo "$tools_used" | jq 'length')" \
        --argjson efficiency "$(echo "$session_data" | jq '.efficiency_rating')" \
        '
        .sessions += 1 |
        .total_duration_ms += $duration |
        .total_tools += $tools |
        .peak_efficiency = (if $efficiency > .peak_efficiency then $efficiency else .peak_efficiency end) |
        .productivity_score = (.total_tools * 1000 / .total_duration_ms)
        ')
    
    echo "$updated_data" > "$daily_file"
) 200>"$daily_file.lock"

# Silent exit for Stop hooks
exit 0