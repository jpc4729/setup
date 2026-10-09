# Composition

The anatomy Laws 1, 2, 5 and 20 assume: the panes a working surface splits into, what each pane owns, the skeletons that repeat inside them, and the edges each one hangs from. Every skeleton here is read off a built surface and carries no identity. Which visual form a fact takes lives in `references/encodings.md`, and color values live in `references/color.md`.

## The three-pane surface

A record under work splits into three vertical panes, separated by one hairline each and by nothing else. The panes do not share a width and they do not share a register.

- Left pane — navigation. Where the reader goes next. Narrow, fixed, quiet, never the subject.
- Center pane — the record at work. The widest pane, and the only one that scrolls a long tail: a trend, a task list, a feed of what happened.
- Right pane — the record itself. Who this is, the numbers that describe it, and the facts that answer a lookup.

The three panes share one top edge and one bottom edge. Each pane's own start edge is the spine of everything inside it. The hairline between two panes is a third edge, and the pane on either side hangs from it.

In the markup the left pane is a labelled `nav`, the center pane is the view's one `main`, and the right pane is a labelled `aside`, so assistive technology meets the same three regions the eye does.

### Sidebar

The spine is the start edge of the icon column. Every row makes contact there with its glyph, and a second contact with the shared start edge of the labels, so the labels form a column of their own. A row is an outline glyph, then a word. Nothing else.

Above the rows sit two fixtures: a workspace row carrying a square mark, the workspace name and a switch affordance, then a search field with its shortcut hint parked on the end edge.

The destination rows come first, undifferentiated on purpose. The current one wears a filled pill and is the only filled row in the pane.

Saved views drop the glyph and lead with a colored dot instead. The dot is the row's whole identity, and the column of dots reads as one set before a single label is read.

Section headings — `SAVED VIEWS`, `SEGMENTS` — are small, uppercase and muted, each with an add affordance on the end edge. They are the pane's landmarks, and there are two of them for twenty rows.

The utility rows at the foot — settings, help, invite — carry no heading. A larger gap is the only cue, and it is enough.

### Main column

The spine is the column's start edge. Every heading, every row and every glyph begins there. Magnitudes and times hang from the opposite end edge, so each row is held by two contacts and needs no divider.

The head of the column is a breadcrumb, then the record's title with an inline edit affordance, then a one-line subline naming the role. An action cluster sits on the end edge, level with the breadcrumb: two single-purpose glyphs and an overflow.

Then the trend. A section heading on the spine, a period selector on the end edge, a line chart with its value axis on the start edge and its time axis under the plot. The magnitude is a shape, not a column of figures.

Then the tasks. A section heading, then group labels — `Tomorrow`, `Next week` — in small muted type above each run of rows. A row is a checkbox on the spine, then the task as a sentence, with the entities inside it promoted in place: a linked document, an avatar beside a name, a category chip. The due time sits on the end edge and lines up with every other due time.

Then the activity. A section heading, then rows led by a ring glyph whose state is the event, the sentence with its actors underlined, and the elapsed time on the end edge. One entry opens into a nested quote block — avatar, author, body — inset from the spine, which is how a reply shows that it belongs to the row above it.

Three regions, three vessels, one spine. The order runs shape, then work, then history.

### Right rail

The rail is a stack of regions on one spine, divided by full-width hairlines and read top to bottom as an answer sheet.

Identity comes first: a cover band, an avatar straddling its lower edge, a social and profile button cluster on the end edge, the name, the role line, then a meta line of location and link each behind its own glyph.

A stat strip closes the identity block. Four columns, label above value, values in the larger weight. The strip's columns are its own edges, and they align to nothing else in the rail.

A chart comes second, with its own heading and period selector, so the rail carries one comparison before it carries any detail rows.

Key-value blocks come third, gathered under collapsible section headings — details, activity, reporting — each heading bearing a chevron on the end edge. The heading predicts the rows beneath it, and the chevron is what keeps a long rail short.

## The key-value row

A key-value row is two columns on two edges. The label column hangs from the region's start edge. The value column hangs from its own start edge, held for every row in the block, so the values form a second column the eye can run down without reading a label.

The label is muted and never wraps. The value carries the weight.

A leading glyph sits inside the value column, before the value, and it is chosen by the data type rather than by the row: a calendar for a date, a person for a person, a place mark for a region, a badge for a level. Rows sharing a type share a glyph, and the glyph column becomes a third edge for free.

A value from a closed set drops the glyph and becomes a chip. A value from an open set stays text.

The row has no divider and needs none, because two edges already hold it.

## The grouped checklist

An enclosure, and inside it a stack of rows on one spine. Each row is a checkbox, then the item as a sentence, then a trailing time on the end edge. Every row's underside is the edge the next row stacks on, which is why the stack reads as built.

Inside the sentence, a document is a link, a category is a chip, and a deadline word is colored where it is near. Each row is a wall of text until those three land in it.

The foot of the enclosure is a bar separated by tone, not by space: a shortcut affordance on the start edge, a named progress value and its ring on the end edge.

## The settings row

The panel opens with a segmented control — four options, each a glyph and a word, the current one wearing a raised pill. Everything under it belongs to that option.

A row is a leading outline glyph on the spine, the setting's name, then the current value as a chip on the end edge, then a chevron. The chip carries its own small glyph and reads as the answer to the name beside it.

The chips form a column, so the panel is scanned by value rather than by label.

One row ends in a toggle instead of a chip. It is the only saturated fill in the panel, because it is the only setting that is on.

## The profile header

A cover band runs the full width. The avatar straddles its lower boundary, wearing a ring that separates it from both surfaces, with a verification mark on its lower corner.

That boundary is a manufactured edge. The avatar hangs from it, and the action cluster on the end edge hangs from it too, which is how a floating portrait gets its second contact.

Below the avatar the spine resumes: name, one-line tagline, then a meta line of location and link behind their glyphs.

A stat strip follows — four columns, label above value — then a hairline, then two actions of unequal weight: one outlined, one plain text.

## The comparison chart

A card. A heading led by a small chart glyph on the spine, a period selector on the end edge.

Three category rows, labels on the spine, bars growing from a shared zero edge, the value axis ticked under the plot. The labels are the card's spine and the zero edge is the plot's, one spine per region.

Each row carries two bars on one track: the current period saturated and in front, the comparison pale and behind. One row, one comparison, no legend.

The pointer lands and a guide drops through the row, with both values stacked beside it, each behind its own dot and named — this period, the average. The figures live in the hidden layer; the shape lives at rest.
