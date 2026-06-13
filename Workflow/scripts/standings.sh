#!/bin/zsh --no-rcs

# Get current/selected season
seasonYear="$(jq -rs 'if (((.[0].Results[0].Date | fromdate) - now) < 7889238) then .[0] else .[1] end | .Results[0].Date[:4]' "${alfred_workflow_data}/nextMatchSeason.json" "${alfred_workflow_data}/prevMatchSeason.json")"
seasonDir="${alfred_workflow_data}/${seasonYear}"

# Auto Update
set -o extendedglob
[[ -f ${alfred_workflow_data}/*/*(#i)standings.json(#qNY1) ]] \
&& [[ "$(date -r "${alfred_workflow_data}" +%s)" -lt "$(date -v -"${autoUpdate}"M +%s)" || ! -d "${alfred_workflow_data}/${seasonYear}" ]] && reload=$(./scripts/reload.sh)

# Get icon for current tournament if present
[[ -f "images/tournaments/${seasonYear}.png" ]] && tournamentIcon="${seasonYear}" || tournamentIcon="fifa"

# Load Standings
jq -cs \
   --arg alfred_workflow_keyword "${alfred_workflow_keyword}" \
   --arg seasonYear "${seasonYear}" \
   --arg icons_dir "images/flags" \
   --arg tournamentIcon "tournaments/${tournamentIcon}" \
   --arg favTeam "$(iconv -f UTF-8-MAC -t UTF-8 <<< ${(L)favTeam})" \
'{
    "variables": {
        "keyword": $alfred_workflow_keyword,
        "seasonYear": $seasonYear,
        "icons_dir": $icons_dir
    },
    "skipknowledge": true,
	"items": (if (length != 0) then
		.[].Results |
		(map({(.Group[0].Description): .Position})) as $groupSeqs |
		(map({(.Group[0].Description): .Team.Name[0].Description})) as $groupTeams |
		map(((.Team.ShortClubName|ascii_downcase) == $favTeam) as $isFavourite | {
			"title": "\(.Position)  \(.Team.ShortClubName)  \(if ((.Team.ShortClubName|ascii_downcase) == $favTeam) then "★" else "" end)",
			"subtitle": "P: \(.Played)    [ W: \(.Won)  D: \(.Drawn)  L: \(.Lost)      GF: \(.For)  GA: \(.Against)  GD: \(.GoalsDiference) ]    Pts: \(.Points)",
			"arg": "stats",
			"match": [
                .Position, .Team.ShortClubName, .Group[0].Description
            ] | map(select(.)) | join(" "),
			"icon": { "path": "\($icons_dir)/\(.Team.IdCountry).png" },
			"text": { "copy": .Team.ShortClubName },
			"variables": { "teamId": .IdTeam, "countryId": .Team.IdCountry, "groupName": .Group[0].Description, "teamName": .Team.ShortClubName, "seq": .Position },
			"mods": {"cmd+shift": {
			    "subtitle": "⇧⌘↩ \(if ($isFavourite) then "Unset" else "Set" end) Favourite Team",
				"variables": { "favTeamNew": .Team.ShortClubName }
			}}
		}) | ([
		    (unique_by(.variables.groupName)[] | select((.variables.seq) == 1)) | (.variables.groupName) as $groupName | ({
				"title":"————————  \($groupName)  ————————",
				"icon":{"path":"images/\($tournamentIcon).png"},
				"match": [
				    $groupName, ($groupSeqs[], $groupTeams[] | ."\($groupName)")
				] | map(select(.)) | join(" "),
				"variables":.variables, "valid": false
			}) | (.variables.seq |= 0)
		]+.)
		| sort_by(.variables.groupName, .variables.seq)
		| [(.[] | select(.variables.seq != 0 and (.variables.teamName|ascii_downcase) == $favTeam)) | (.match |= "")] + .
	else
		[{
			"title": "No Standings Found",
			"subtitle": "Press ↩ to load standings for the current year",
			"arg": "reload"
		}]
	end)
}' "${seasonDir}/standings.json"