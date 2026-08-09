#!/bin/zsh --no-rcs

mkdir -p "${alfred_workflow_data}"
seasons_file="${alfred_workflow_data}/seasons.json"
currentYear="$(date +%Y)"
seasonYear="$((currentYear - (currentYear - 1930) % 4))"

# Conditionally download season files
function getSeason {
    seasonData=($(jq -r '.Results[0] | [.Date[:4], .IdSeason, .IdStage] | join(" ")' "${seasons_file}"))
    seasonDir="${alfred_workflow_data}/${seasonData[1]}"
}
[[ -f "${seasons_file}" ]] && getSeason
[[ "${seasonData[1]}" -eq "${seasonYear}" ]] && downloadStatus=1 || curl -sf --compressed --connect-timeout 5 -L "https://api.fifa.com/api/v3/calendar/matches?language=en&count=1&IdCompetition=17&from=${seasonYear}-01-01" -o "${seasons_file}" && downloadStatus=1 && getSeason

# Get season standings, schedule, and stats
if [[ -n "${downloadStatus}" ]]; then
    mkdir -p "${seasonDir}"
    curl -sf --compressed --parallel --max-time 10 \
        -L "https://api.fifa.com/api/v3/calendar/17/${seasonData[2]}/${seasonData[3]}/standing?language=en&count=200" -o "${seasonDir}/standings.json" \
        -L "https://api.fifa.com/api/v3/calendar/matches?language=en&count=500&idSeason=${seasonData[2]}" -o "${seasonDir}/schedule.json" \
        -L "https://fdh-api.fifa.com/v1/stats/season/${seasonData[2]}/teams.json" -o "${seasonDir}/stats.json"
    # set -o extendedglob
    # if [[ -f "${seasonDir}/standings.json" && ! -n ${seasonDir}/icons/*.png(#qNY1) ]]; then
    #     # Get Team Logos
    #     mkdir -p "${seasonDir}/icons"
    #     teamIds=$(jq -r '[.Results[].Team.IdCountry] | join(",")' "${seasonDir}/standings.json")
    #     curl -sf --compressed --parallel --output-dir "${seasonDir}/icons" -L "https://api.fifa.com/api/v3/picture/flags-sq-4/{${teamIds}}" -o "#1.png"
    #     sips -p 250 250 ${seasonDir}/icons/*.png >/dev/null
    # fi
    touch "${alfred_workflow_data}"
    printf "Standings Updated"
else
    printf "Standings not Updated"
fi