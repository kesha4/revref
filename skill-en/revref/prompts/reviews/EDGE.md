# EDGE — Edge cases

Finding ID prefix: EDGE. Use together with `prompts/common-rules.md`.

Review edge case handling — places that lack protection against unusual but possible inputs and situations. For every public API, handler, form and critical path, check what happens with:
- null, undefined, an empty string, an empty array, a missing or extra field;
- zero, negative numbers, type boundary values, very large numbers, NaN;
- very long strings, large files, huge lists;
- Unicode, emoji, RTL text, leading and trailing whitespace, different letter case;
- duplicates, resubmission (double click, request retry), concurrent requests to the same resource;
- dates: time zones, daylight saving time transitions, February 29, end of month and year; different number and date formats in different locales;
- an error, timeout, empty or unexpected response from an external system; a failure in the middle of a multi-step operation; no network.

Where is validation missing at the system boundaries: user input, external APIs, files, environment variables?

Present findings as a table: scenario → current behavior → expected behavior → proposed protection.

Errors that show up under normal use belong to the bugs review, and those exploitable by an attacker belong to the security review (record them in "Seen in passing").
