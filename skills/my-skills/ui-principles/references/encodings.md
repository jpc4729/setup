# Encodings

The catalogue the gate and Laws 6, 10 and 17 assume: one kind of fact per section, the form it takes, the anatomy of that form, an observed example, and the condition that breaks it. The examples come from the skeletons in `references/composition.md`: the CRM is its three-pane surface, the user card its profile header, the checklist its grouped checklist, the settings panel its settings row, and the Expense report its comparison chart. Color values live in `references/color.md`.

## Person

A person is a face. A round avatar at the height of the line it sits in, the name beside it, and a badge on the lower corner for a fact about the person rather than about the account. The CRM task row reads "Upload Q2 invoice folder to Jeff in accounting" with Jeff's avatar inline at line size, and the user card enlarges that same avatar over a cover band and hangs a blue check on its lower right. The face fails when the audience does not already hold it: an unfamiliar avatar is a colored disc, and initials rank below the name they abbreviate.

## Category or tag

A category is a chip. A rounded fill, a label in one or two words, and a leading glyph when the category has a kind — the VC chip in the task list carries a folder, the Finance chip a card, the Payroll chip a document. The chip fails when the set is open: a free string in a chip promises a set that does not exist, and Law 6 already leaves open strings as text.

## Status

A status is a chip whose fill traces to the state it names, with the state spelled out in the label. "Closed won" sits green in the activity feed, a word pair no reader decodes. The status chip fails when every value in the set is lit: with all of them accented nothing ranks, and Law 9 already rules which values earn the fill.

## State transition

A transition is a feed row: a state glyph on the start edge, a verb phrase naming the change, a time on the end edge. The glyphs stack into a rail, and the glyph itself carries the outcome in its hue, one ring construction throughout. The CRM activity reads a green ring for "Marked OpenAI deal as Closed won", a blue ring for "Sent message to Taylor Halliday", a gray ring for "Opened OpenAI opportunity". The form fails when there is no prior state to leave: an event with nothing before it is a log line, not a transition.

## Due date and relative time

A near deadline reads relative, a far one reads absolute, both behind a clock glyph. The CRM groups tasks under "Tomorrow" and "Next week", then prints "9:30am" and "1pm" inside the first group and "in 5 days", "in 6 days", "in 7 days" inside the second; the checklist promotes "in 1 day" and "in 2 days" into a filled chip while the rows with no deadline keep a bare clock outline. The absolute date stays reachable under the relative one. Relative time fails past the reader's mental calendar, where "in 94 days" is arithmetic and a date is not, and it fails on a surface left open, where the text ages while the page does not.

## Magnitude

A magnitude is a bar from a shared baseline, ordered longest first, read against ticks rather than labels. The Expense report runs Software, AI Credits and Servers against a 0 to 10K axis and lays a pale bar behind each colored one so the comparison sits in the same row. The bar fails with one value and no scale: a lone bar carries no more than the number printed on it.

## Trend over time

A trend is a line on a time axis, the series that matters drawn dark and its comparison drawn pale. Total sales runs one saturated line over one washed line across Sep 2, Oct 8, Nov 16 and Today, and the direction registers before a single value is read. The line fails when the points are few or unordered: three readings are three numbers, and a line drawn through them invents the path between.

## Link

A link is the target's own name, in the accent, underlined, inside the sentence that needs it. The checklist underlines "Q2 invoice folder" mid-row and the CRM task list underlines "tax filings", while the profile prints "joy.studio" beside a chain glyph. The CRM message body prints "Taylor" in the accent with no underline, which is this rule's failure and not its example. The underline is the signal the color is not allowed to carry alone, per Law 10. The link fails when the label is not the target: a bare URL, or a word that names the act of clicking rather than what arrives.

## File and folder

A file is a glyph stating its kind, the name in the file's own casing, and the extension kept. The checklist footer names "JBW_Invoices_Q2" beside its progress, and the VC chip states folder with a folder glyph rather than with the word. The form fails when one glyph serves every kind: an identical mark on a spreadsheet, a deck and a folder returns the reader to the filename.

## Boolean

A boolean applied on the spot is a toggle; a boolean committed with a form is a checkbox. The settings panel gives "Keep human edits" a filled blue track, and the six checklist rows sit as thin square outlines with no fill at all, since off is the absence of the signal. The toggle fails when the change is not immediate or not cheap to reverse: an action that needs a confirmation is a button on the rung Law 13 sets, and a fact with a third value is an enum.

## Enum

An enum is the current value on the surface and the set one tap behind it: a monochrome chip carrying a leading glyph and the value in words, with the chevron on the row outside it. The settings panel reads down a column of them — "Suggest only", "Blank only", "Stale > 30d", "Sources only", "Save as suggestion" — so the whole configuration is legible without opening anything. The chip fails when the set outgrows one menu, and when the values are not exclusive, since a chip that shows one value hides the others that are also true.

## Tier or level

A tier is an ordered set: a segmented control where the tier is chosen, a code and its name where the tier is read. The settings panel lays Custom, Safe, Standard and Full across one track with Safe held, and the Level row prints "IC3 — Senior" so the code and its meaning arrive together. The form fails when the reader does not hold the ladder: a code alone ranks nothing, and a rank with no visible neighbors is a label.

## Count and quantity

A count is the number set large with its noun small above it, in figures that line up by place value and with thousands grouped. The user card runs Followers 31,261, Following 3,841, Posts 119 and Stars 41 across one row, and the CRM panel repeats the pattern with Clients 119. `font-variant-numeric: tabular-nums` holds the columns. The count fails when the reader came for its direction rather than its size, which the trend form carries instead.

## Owner or assignee

An owner is a face and a name on the row that owns the fact, and the empty case is a named slot rather than a blank. The CRM prints Manager "Lisa Nakamura" and Director "Tom Martinez" behind a person glyph, and the sidebar gives "Unassigned" a saved view of its own. The form fails when one row carries many owners: past a few faces the stack becomes a count with a face on it.

## Progress

Progress is a ring where the space is one row tall and a bar where the region is wide, with the percentage printed beside it. The checklist footer draws a quarter-turned ring next to "JBW_Invoices_Q2: 25%", so the share and the figure land together in the height of the bar. The form fails when the total is unknown: a determinate arc over an unknown denominator states a fact the system does not have.

## Location

A location is a pin and a place name at the granularity the reader acts on, or a region code where the place is an operating area. The user card and the CRM panel both read "New York City, NY" behind a pin, and the Region row reads "West — NA" behind a globe. The form fails when the reader needs a position relative to something else, which a name cannot give and a map can.

## Currency

Currency is the symbol, the figure, and a magnitude suffix once the digits outrun the column, hung on the end edge in figures that line up by place value. The CRM panel sets Revenue $782k beside Pipeline $29.3k, and the chart tooltip stacks "$6,214 this week" over "$5,706 average" so the two amounts compare digit against digit. The form fails when the rounding swallows the difference the reader came for, and when two currencies share one column with no code to separate them.
