#!/bin/zsh --no-rcs

# Get lastest cache timestamp
readonly lastUpdated=$(date -r "${alfred_workflow_data}" +"%A, %B %d %Y at %I:%M%p" || printf "Never")

cat << EOB
{"items": [
	{
		"title": "Reload Standings & Schedule",
		"subtitle": "Last Updated: ${lastUpdated}",
		"variables": { "pref_id": "reload", "keyword": "${${alfred_workflow_keyword%% ::}%%::}" }
	},
	{
		"title": "Open Current FIFA World Cup in Browser",
		"arg": "https://www.fifa.com/worldcup",
		"variables": { "pref_id": "open" }
	},
	{
		"title": "Configure Workflow...",
		"subtitle": "Open the configuration window for ${alfred_workflow_name}",
		"arg": "alfredpreferences://navigateto/workflows>workflow>${alfred_workflow_uid}>userconfig",
		"variables": { "pref_id": "configure" }
	}
]}
EOB