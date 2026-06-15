#!/bin/zsh --no-rcs

# Get time since last reload in minutes
stats_file="${alfred_workflow_data}/${seasonYear}/stats.json"
minutes="$((($(date +%s)-$(date -r "${alfred_workflow_data}" +%s))/60))"

# Download Stats Data
if [[ "${forceReload}" -eq 1 ]]; then
    # Rate limit to only refresh if data is older than 1 minute
    [[ "${minutes}" -gt 0 || -z "${minutes}" ]] && reload=$(./scripts/reload.sh) && minutes=0
fi

# Format Last Updated Time
if [[ ${minutes} -eq 0 ]]; then
    lastUpdated="Just now"
elif [[ ${minutes} -eq 1 ]]; then
    lastUpdated="${minutes} minute ago"
elif [[ ${minutes} -lt 60 ]]; then
    lastUpdated="${minutes} minutes ago"
elif [[ ${minutes} -ge 60 && ${minutes} -lt 120 ]]; then
    lastUpdated="$((${minutes}/60)) hour ago"
elif [[ ${minutes} -ge 120 && ${minutes} -lt 1440 ]]; then
    lastUpdated="$((${minutes}/60)) hours ago"
else
    lastUpdated="$(date -r "${alfred_workflow_data}" +'%Y-%m-%d')"
fi

# Format Stats to Markdown
if [[ -f "${stats_file}" ]]; then
    mdOutput=$(jq -crs --arg countryId "${countryId}" --arg teamId "${teamId}" --arg teamName "${teamName}" --arg icons_dir "${icons_dir}" \
    '.[]."\($teamId)" | if (.) then map({(.[0]): .[1]}) | add | 50 as $spaces |
        "![Team Logo](\($icons_dir)/\($countryId)small.png)\n",
        "# \($teamName)",
        "\n**Matches Played:** \(.MatchesPlayed)      ·      **Time Played:** \(.TimePlayed | if (.) then "\(.|round) minutes" else "null" end)",
        "\n***\n\n### Attacking\n\n```",
        ("Goals:"|.+" "*($spaces-length))+"\(.Goals)",
        ("Assists:"|.+" "*($spaces-length))+"\(.Assists)",
        ("Attempts At Goal (On Target %):"|.+" "*($spaces-length))+(if (.AttemptAtGoal) then "\(.AttemptAtGoal) (\(.AttemptAtGoalOnTarget/.AttemptAtGoal*100|round)%)" else "null" end),
        ("Attempts At Goal Inside The Penalty Area:"|.+" "*($spaces-length))+"\(.AttemptAtGoalInsideThePenaltyArea)",
        ("Attempts At Goal Outside The Penalty Area:"|.+" "*($spaces-length))+"\(.AttemptAtGoalOutsideThePenaltyArea)",
        ("Penalties (Scored):"|.+" "*($spaces-length))+(if (.Penalties) then "\(.Penalties) (\(.PenaltiesScored))" else "null" end),
        ("Free Kicks:"|.+" "*($spaces-length))+"\(.FreeKicks)",
        ("Corners:"|.+" "*($spaces-length))+"\(.Corners)",
        ("Crosses (Completed %):"|.+" "*($spaces-length))+(if (.Crosses) then "\(.Crosses) (\(.CrossesCompleted/.Crosses*100|round)%)" else "null" end),
        "```\n\n### Defending\n\n```",
        ("Goals Conceded:"|.+" "*($spaces-length))+"\(.GoalsConceded)",
        ("Own Goals:"|.+" "*($spaces-length))+"\(.OwnGoals)",
        ("Clean Sheets:"|.+" "*($spaces-length))+"\(.CleanSheets)",
        ("Attempts At Goal Against:"|.+" "*($spaces-length))+"\(.AttemptAtGoalAgainst)",
        ("Attempts At Goal Blocked:"|.+" "*($spaces-length))+"\(.AttemptAtGoalBlocked)",
        ("Defensive Pressures Applied:"|.+" "*($spaces-length))+"\(.DefensivePressuresApplied)",
        ("Forced Turnovers:"|.+" "*($spaces-length))+"\(.ForcedTurnovers)",
        ("Pressing Applied:"|.+" "*($spaces-length))+"\(.DefensivePressuresApplied)",
        "```\n\n### Possession\n\n```",
        ("Passes (Completed %):"|.+" "*($spaces-length))+(if (.Passes) then "\(.Passes) (\(.PassesCompleted/.Passes*100|round)%)" else "null" end),
        ("Distributions Under Pressure (Completed %):"|.+" "*($spaces-length))+(if (.DistributionsUnderPressure) then "\(.DistributionsUnderPressure) (\(.DistributionsCompletedUnderPressure/.DistributionsUnderPressure*100|round)%)" else "null" end),
        ("Attempted Switches of Play (Completed):"|.+" "*($spaces-length))+(if (.AttemptedSwitchesOfPlay) then "\(.AttemptedSwitchesOfPlay) (\(.CompletedSwitchesOfPlay))" else "null" end),
        ("Linebreaks Attempted (Completed):"|.+" "*($spaces-length))+(if (.LinebreaksAttempted) then "\(.LinebreaksAttempted) (\(.LinebreaksAttemptedCompleted))" else "null" end),
        "```\n\n### Disciplinary\n\n```",
        ("Red Cards:"|.+" "*($spaces-length))+"\(.RedCards)",
        ("Yellow Cards:"|.+" "*($spaces-length))+"\(.YellowCards)",
        ("Offsides:"|.+" "*($spaces-length))+"\(.Offsides)",
        ("Fouls For/Against:"|.+" "*($spaces-length))+"\(.FoulsFor) / \(.FoulsAgainst)",
        "```"
    else
        "![Team Logo](\($icons_dir)/\($countryId)small.png)\n# \($teamName)\n\n**Matches Played:** N/A      ·      **Time Played:** N/A\n\n***\n\n*No Team Stats available*"
    end' "${stats_file}" | sed 's/\"/\\"/g')
else
    mdOutput="![Team Logo](${icons_dir}/${countryId}small.png)\n# ${teamName}\n\n**Matches Played:** N/A      ·      **Time Played:** N/A\n\n***\n\n*No Team Stats available*"
fi

# Output Formatted Stats to Text View
cat << EOB
{
    "variables": { "forceReload": 1 },
    "response": "${mdOutput//$'\n'/\n}",
    "footer": "Last Updated: ${lastUpdated}            ⌥↩ Update Now"
}
EOB