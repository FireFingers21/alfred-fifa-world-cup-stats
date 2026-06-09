# <img src='Workflow/icon.png' width='45' align='center' alt='icon'> FIFA World Cup Stats

View the current FIFA World Cup standings &amp; stats in Alfred

## Setup

This workflow requires [jq](https://jqlang.github.io/jq/) to function, which comes preinstalled on macOS 15 Sequoia and later.

## Usage

View the current [FIFA World Cup](https://www.fifa.com/worldcup) schedule via the `sfifa` keyword, adjusted to your local time zone. Type to filter by Country, Group, Stadium/City, Stage/Knockout, Date, or Favourite.

![Using the sfifa keyword](Workflow/images/about/keywordSchedule.png)

* <kbd>↩</kbd> Open Match in Browser.
* <kbd>⌥</kbd><kbd>↩</kbd> Show/Hide Old Matches.

Use the `fifa` keyword to view the current World Cup Standings. Type to filter by Country, Position, or Group.

![Using the fifa keyword](Workflow/images/about/keywordStandings.png)

* <kbd>↩</kbd> View Team Stats in Alfred.
* <kbd>⇧</kbd><kbd>⌘</kbd><kbd>↩</kbd> Set/Unset Favourite Team.

Additional Team Stats can be viewed directly within Alfred. This includes Attacking, Defending, Possession, and Disciplinary Stats.

![Viewing team stats in the Text View](Workflow/images/about/stats.png)

* <kbd>⌥</kbd><kbd>↩</kbd> Refresh Team Stats.

Append `::` to the configured [Keywords](https://www.alfredapp.com/help/workflows/inputs/keyword) to access other actions, such as manually reloading the Standings & Schedule cache.

![Other actions](Workflow/images/about/inlineSettings.png)

Configure the [Hotkeys](https://www.alfredapp.com/help/workflows/triggers/hotkey/) as shortcuts for viewing the standings and schedule.