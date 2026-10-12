# RWD — Responsive UI

Finding ID prefix: RWD. Use together with `prompts/common-rules.md`.

Review how responsive the interface is across all screen sizes — from mobile to wide monitors.

Check at least widths of 320, 375, 414, 768, 1024, 1280, 1440, 1920 and 2560+ px, as well as phone landscape orientation and 200% page zoom. If a browser is available, check the actual render via screenshots, not just the code.

At all sizes:
- do layouts reflow correctly when the window width changes, is there no horizontal scroll;
- fixed widths and heights in pixels, clipped, stretched or overlapping content, elements crammed together or drifting apart;
- long content: long words, names, URLs, translations into other languages, large numbers;
- images and media: srcset, aspect-ratio, sharpness on high-density screens;
- tables, modal dialogs, dropdown menus and forms.

Narrow screens and touch devices:
- is text readable without zooming, do controls stay visible;
- interactive elements are at least 44×44 px, with enough spacing between them;
- interactions available only on hover;
- 100vh on mobile (jumps because of the address bar), safe-area on screens with a notch;
- the on-screen keyboard does not cover the active field and the submit button.

Wide screens:
- content does not stretch to the full width without limits, a line of text stays readable (guideline: 60–80 characters);
- no empty gaps or broken composition.

For each issue: file, line, at which sizes it breaks, what exactly breaks, a concrete fix.
