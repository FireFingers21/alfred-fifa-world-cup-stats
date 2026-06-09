#!/bin/zsh --no-rcs

mkdir -p "${alfred_workflow_data}"
next_season_file="${alfred_workflow_data}/nextMatchSeason.json"
prev_season_file="${alfred_workflow_data}/prevMatchSeason.json"
nextSeasonDate="$(date +%Y)-01-01"
lastSeasonDate="$(date -jv-4y +%Y)-01-01"

# Conditionally download season files
function getSeason {
    # Get standings for current/selected season
    seasonData=($(jq -rs 'if (((.[0].Results[0].Date | fromdate) - now) < 7889238) then .[0] else .[1] end | .Results[0] | [.Date[:4], .IdSeason, .IdStage] | join(" ")' "${next_season_file}" "${prev_season_file}"))
    seasonDir="${alfred_workflow_data}/${seasonData[1]}"
}
[[ -f "${next_season_file}" && -f "${prev_season_file}" ]] && getSeason
if [[ "$((nextSeasonDate[1,4]-seasonData[1]))" -lt 4 && "$((nextSeasonDate[1,4]-seasonData[1]))" -gt -4 ]]; then
    downloadStatus=1
else
    curl -sf --compressed --parallel --connect-timeout 10 \
        -L "https://api.fifa.com/api/v3/calendar/matches?language=en&count=1&IdCompetition=17&from=${nextSeasonDate}" -o "${next_season_file}" \
        -L "https://api.fifa.com/api/v3/calendar/matches?language=en&count=1&IdCompetition=17&from=${lastSeasonDate}" -o "${prev_season_file}" \
    && downloadStatus=1
    getSeason
fi

if [[ -n "${downloadStatus}" ]]; then
    # Get season standings, schedule, and stats
    mkdir -p "${seasonDir}"
    curl -sf --compressed --parallel --connect-timeout 10 \
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