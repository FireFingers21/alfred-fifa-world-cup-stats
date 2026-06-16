#!/bin/zsh --no-rcs

# Get current/selected season
currentYear="$(date +%Y)"
seasonYear="$((currentYear - (currentYear - 1930) % 4))"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Limit Auto Update & set condition for live scores
if [[ -f "${seasonDir}/schedule.json" ]]; then
    scheduleData=($(jq -r '[.Results | all(.OfficialityStatus == 1), all(.MatchStatus <= 1 and ((now - (.Date|fromdate)) > 3600 or (now - (.Date|fromdate)) < 0)), .[0].IdSeason] | join(" ")' "${seasonDir}/schedule.json"))
    gamesFinished="${scheduleData[1]}"
fi

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)schedule.json(#qNY1) && "${gamesFinished:=false}" = false ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${seasonDir}" ]] && reload=$(./scripts/reload.sh)

# Generate Live Scores
[[ "${scheduleData[2]}" == false && "$(date -r "${seasonDir}/schedule.json" +%s)" -lt "$(date -v -15S +%s)" ]] && curl -sf --compressed --connect-timeout 5 -L "https://api.fifa.com/api/v3/calendar/matches?language=en&count=500&idSeason=${scheduleData[3]}" -o "${seasonDir}/schedule.json"

# Get icon for current tournament if present
[[ -f "images/tournaments/${seasonYear}.png" ]] && tournamentIcon="${seasonYear}" || tournamentIcon="fifa"

# Load Schedule
jq -cs \
   --arg alfred_workflow_keyword "${alfred_workflow_keyword}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
   --arg tournamentIcon "tournaments/${tournamentIcon}" \
   --argjson spoilSchedule "${spoilSchedule}" \
   --argjson spoilSearch "${spoilSearch}" \
   --argjson showNowTime "${showNowTime}" \
   --argjson showDoneTime "${showDoneTime}" \
   --argjson showOldEvents "${showOldEvents:=0}" \
   --slurpfile nocDict "nocDict.json" \
'{
    "variables": { "keyword": $alfred_workflow_keyword },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[].Results | map(
		(.Home | .ShortClubName // .TeamName[0].Description // "") as $homeClubName |
		(.Away | .ShortClubName // .TeamName[0].Description // "") as $awayClubName |
		(.Date | fromdate) as $Date |
		($Date | strflocaltime("%b %d") + " "*12) as $subDate |
		($spoilSchedule == 0 and (.StageName[0].Description|ascii_downcase) != "first stage") as $spoiler |
		(if (.MatchStatus > 1) or (.MatchStatus != 0 and now >= ($Date) and now < ($Date+7200)) then "Now"+" "*8 else false end) as $isNow |
		(if (.MatchStatus == 0) then "Done"+" "*7 else false end) as $isDone |
		((if ($showDoneTime != 1) then $isDone else false end) // (if ($showNowTime != 1) then $isNow else false end) // ($Date | strflocaltime("%H:%M") | .+" "*(if (split("1")|length>2) then 7 else 6 end))) as $localStartTime |
		(if ($spoiler or .Home == null) then .PlaceHolderA else $nocDict[0].emoji."\(.Home.IdCountry)" + " \($homeClubName)\(if ($spoilSchedule == 1 and .Home.Score != null) then "    \(.Home.Score)" else "" end)" end) as $competitorHome |
		(if ($spoiler or .Away == null) then .PlaceHolderB else (if ($spoilSchedule == 1 and .Away.Score != null) then "\(.Away.Score)    " else "" end) + $nocDict[0].emoji."\(.Away.IdCountry)" + " \($awayClubName)" end) as $competitorAway |
		($favTeam != "" and (($homeClubName|ascii_downcase) == $favTeam or ($awayClubName|ascii_downcase) == $favTeam)) as $isFavourite |
		{
			"title": "\($localStartTime)\($competitorHome)  /  \($competitorAway)",
			"subtitle": "\($subDate)\(.StageName[0].Description)   –   \(.GroupName[0].Description | if (.) then "\(.)   –   " else "" end)\(.Stadium.Name[0].Description)",
			"arg": "\(.IdCompetition)/\(.IdSeason)/\(.IdStage)/\(.IdMatch)",
			"match": [
                .StageName[0].Description, "\"\(.Stadium.Name[0].Description)\"", "\"\(.Stadium.CityName[0].Description)\"",
                (if (($spoiler | not) or $spoilSearch == 1) then ($homeClubName, $awayClubName) else "" end),
                (.GroupName[0].Description | if (.) then "\"\(.)\"" else "" end),
                (if ((.StageName[0].Description|ascii_downcase) != "first stage") then "knockout" else "" end),
                ($Date | strflocaltime("\"%B %d\"%e\"")),
                (if ($isNow) then "live now" elif ($isDone) then "finished done" else "upcoming" end),
                (if ($isFavourite) then "favourite" else "" end)
            ] | map(select(.)) | join(" "),
			"icon": { "path": "images/\(if ($isFavourite) then "favourite" else $tournamentIcon end)\(if $isNow then "live" elif $isDone then "done" else "" end).png" },
			"stale": ((now - $Date) > (36*3600)),
			"mods": {
			    "alt": {
			        "subtitle":"\($subDate)⌥↩ \(if ($showOldEvents == 1) then "Hide" else "Show" end) old matches",
					"variables": { "showOldEvents":($showOldEvents == 1 | not) }
				},
			    "ctrl": {
			        "subtitle":"\($subDate)⌥↩ \(if ($spoilSchedule == 1) then "Hide" else "Show" end) spoilers",
					"variables": { "spoilSchedule":($spoilSchedule == 1 | not) }
				}
			}
		}) | select($showOldEvents == 1 or isempty(.[] | select(.stale | not))) // [.[] | select(.stale | not)]
	else
		[{
			"title": "No Schedule Found",
			"subtitle": "Press ↩ to load the schedule for the current year",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/schedule.json"