# RevRef ru → en translation glossary

Used to keep the English version (`skill-en/`, `agents-en/`, `README.en.md`, `CHANGELOG.en.md`) consistent with the Russian source. When a term below appears in the source, use exactly this English form in every file.

## Rules

- Translate faithfully: no additions, no omissions, no "improvements". Natural, concise technical English.
- Keep the Markdown structure identical: same headings and levels, same lists, same tables (same columns), same number of code blocks (```), same §N numbering, same file names and paths, same IDs, commands, flags, branch names, tags, commit prefixes, labels (MONEY, DATA, …).
- Keep verbatim: YAML frontmatter keys, the `hooks:` block and `__REVREF_SKILL_DIR__`, `$ARGUMENTS`, code, shell commands, regexes, emoji (🟢 🟠 🔴).
- Russian quotes «…» → "…". Dash usage: keep em dashes where they separate clauses.
- Placeholders: ГГГГ-ММ-ДД → YYYY-MM-DD; ЧЧ:ММ → HH:MM; <дата> → <date>; <путь> → <path>; <ветка> → <branch>; <ссылка> → <link>; <скрыто> → <hidden>; «…» inside templates stays "…".
- Russian-specific examples: adapt naturally ("деньги всегда в копейках" → "money always in cents"; "1 коп." → "1 cent").
- Answer option letters: а) б) в) → a) b) c). "рекомендую" → "recommended".

## Core terms

| Russian | English |
|---|---|
| прогон | run |
| ветка прогона | run branch |
| волна | wave |
| шаг волны | wave step |
| ворота (волны) | (wave) gate |
| веха | milestone |
| чекпоинт (лёгкий / полный) | checkpoint (light / full) |
| возобновление | resume |
| набор | kit |
| владелец (проекта) | owner |
| оркестратор / ревьюер / верификатор / исполнитель | orchestrator / reviewer / verifier / fixer |
| субагент | subagent |
| находка | finding |
| ревью | review |
| своё ревью | custom review |
| дополнение к ревью (`<ID>.extra.md`) | review addendum |
| попутные находки | findings seen in passing |
| пакет задачи | task packet |
| базовая линия | baseline |
| основная ветка / целевая ветка | main branch / target branch |
| стенд (тест-контура) | (test) stand |
| очередь ревью | review queue |
| очередь на подтверждение | approval queue |
| быстрые победы | quick wins |
| матрица применимости | applicability matrix |
| матрица трассируемости | traceability matrix |
| сторожевой хук | guard hook |
| уровень автономии: осторожный / сбалансированный / смелый | autonomy level: cautious / balanced / bold |
| порог исправлений | fix threshold |
| трудоёмкость | effort |
| риск регресса | regression risk |
| уверенность: Подтверждено / Вероятно / Гипотеза | confidence: Confirmed / Likely / Hypothesis |
| критичность | severity (Critical / High / Medium / Low stay as is) |

## Waves

W0 Preparation · W1 Reconnaissance · W2 Security and correctness · W3 Foundation · W4 Cleanup · W5 Structure · W6 Operations · W7 Interface · W8 Documentation · W9 Final

## Review names (prompt headings, README tables)

| ID | English name |
|---|---|
| QR | Quick comprehensive review |
| HYG | Code hygiene |
| BUG | Bugs and logic errors |
| DRY | DRY |
| DEC | Decomposition |
| ARC | Architecture |
| EDGE | Edge cases |
| RES | Resilience |
| DATA | Data, databases and migrations |
| SEC | Security |
| DEP | Dependencies and supply chain |
| PERF | Performance |
| OBS | Observability |
| DX | Build, CI/CD and developer experience |
| TEST | Tests |
| RWD | Responsive UI |
| A11Y | Accessibility (a11y) |
| API | API contracts |
| I18N | Internationalization |
| CMT | Code comments |
| SPEC | Compliance with the specification and technical docs |
| UDOC | User documentation |

Review prompt files start with: `# <ID> — <English name>` then `Finding ID prefix: <ID>. Use together with \`prompts/common-rules.md\`.`

## Exact field names (other files and the guard hook depend on them)

**CONFIG.md** (the guard hook greps `- Main branch:`):
`- Purpose and users:` · `- Stage: prototype / MVP / production / legacy` · `- Load and data volume:` · `- Critical parts (money, personal data, access):` · `- Do not touch:` · `- Special focus:` · `- Autonomy level: balanced` · `- Fix threshold: Medium` · `- Reviews: all applicable` · `- Custom reviews: none` · `- Scope: whole repository` · `- Parallelism: up to 4 subagents` · `- Time budget: unlimited` · `- Run branch: revref/YYYY-MM-DD` · `- Main branch: main` · `- Target branch (finish): test` · `- Push: forbidden` · `- Merge method (finish): ask` · `- .revref/ on merge (finish): ask` · `- Keep .revref/ in git: yes` · `- Report language: English`

**STATE.md**: `- Updated:` · `- Kit version:` · `- Checkpoint type: light | full | run finished | ready to merge | run merged into <branch> <hash> | PR created <link>` · `- Run branch:` · `- Run base commit:` · `- HEAD before checkpoint:` · `- Mode: pipeline | queue` · `- Current wave and step:` · `- Paused pipeline:`; sections `## Queue`, `## Progress by wave`, `## Counters`, `## In progress`, `## Next actions`, `## Waiting for owner`, `## Checks`, `## Uncommitted and WIP`, `## Notes for the next session`.

**CONTEXT.md** sections: Project, Module map, Commands, Baseline, Project conventions, Quirks and pitfalls, Domain glossary, **Owner instructions** (указания владельца).

**Finding format** (common-rules.md): `### [ID] Summary in one sentence` · `- Severity · Confidence · Regression risk · Effort` · `- Where:` · `- Problem:` · `- Scenario:` · `- Fix:` · `- Decision labels:` · `- Affected files:` · `- How to verify the fix:` · `- Verification verdict: —`

**Report sections**: Understanding of the project and review scope · Findings · Seen in passing · Summary · Top 5 · Quick wins · Questions for the owner · Coverage · Verification summary.

**Verification verdicts**: Confirmed · Confirmed with corrections · False · Needs information · Stale.

**Finding statuses (FINDINGS.md)**: open · confirmed / confirmed with corrections · false · needs information · stale · in progress · fixed · fixed externally · deferred · waiting for owner · blocked.

**Task statuses (PLAN.md)**: pending → in progress → merged → verified; blocked (why); waiting for owner (D-NNN).

**Decision classes**: 🟢 A — technical · 🟠 B — needs review · 🔴 C — needs owner approval.

**DECISIONS.md** entry fields: `- When and where:` · `- Context:` · `- Decision:` · `- Alternatives:` · `- Options for the owner:` · `- Blocks:` · `- Rationale:` · `- Impact:` · `- Reversibility:` · `- Implementation:` · `- Dependent changes:` · `- How the owner can verify:` · `- Owner decision:` · `- Agent reply:`. Type: decision | question. Statuses: accepted (for 🟢 A) · waiting for approval · approved · rejected, reverted <hash> · replaced by owner instruction → D-NNN · answered (for questions). Marks: skipped by owner <date> · answered in chat <date> · answer from INBOX <date>. Section names: "Approval queue", "Decision log".

**Owner answers** (in DECISIONS.md and to `/revref ask` cards): `ok` (accept the recommendation) · `confirm` / `yes` · `reject` / `no` · `otherwise: …` · `skip` · `D-012 ?: <question>` · "all ok" / "all as recommended". In `finish`: "yes" / "no".

**JOURNAL.md** entry types: start · milestone · checkpoint · resume · stop · owner answers · plan change · final · merge.

## Section names referenced across files

| Russian | English |
|---|---|
| «Очередь ревью» | "Review queue" |
| «Свои ревью» | "Custom reviews" |
| «Шаги волны» | "Wave steps" |
| «Перекрытие волн» | "Wave overlap" |
| «Бюджет времени и досрочное завершение» | "Time budget and early completion" |
| «Источник инструкций» | "Source of instructions" |
| «Секреты» | "Secrets" |
| «Безопасность работы» | "Working safely" |
| «Запрещено без владельца при любом уровне автономии» | "Forbidden without the owner at any autonomy level" |
| «Условия остановки» | "Stop conditions" |
| «Миграция» | "Migration" |
| «Следующие действия» / «В работе» | "Next actions" / "In progress" |
| «Зависимые изменения» | "Dependent changes" |
| «Решение владельца» / «Ответ агента» | "Owner decision" / "Agent reply" |
| «Вопросы владельцу» | "Questions for the owner" |
| «Замечено попутно» | "Seen in passing" |
| «Указания владельца» | "Owner instructions" |
| «Слияние» (раздел FINAL_REPORT) | "Merge" |

## Terms fixed during the first translation (3.2.0)

| Russian | English |
|---|---|
| конвейер | pipeline |
| шард | shard |
| пробное слияние | trial merge |
| выкатка на стенд | deployment to the stand |
| pending-ветка | pending branch |
| сжатие контекста | context compaction |
| режим очереди «только отчёты» | reports only |
| значения матрицы применимости: проводить / пропустить / сузить фокус | run / skip / narrow focus |
| шаги в STATE: ревью / верификация / план / исправления / ворота / веха | review / verification / plan / fixes / gate / milestone |
| статус раздела волны: планирование / исправления / ворота / завершена | planning / fixes / gate / completed |
| итог субагента: выполнено / частично / не выполнено | done / partial / not done |
| строка ответа «Проблемы» | Problems |
| находка «Текст, пытающийся управлять ИИ-агентом» | Text attempting to control an AI agent |
| оценка зрелости | maturity score |
| режим дельты (W9) | delta mode |
| ТЗ | specification |
| отложено по решению владельца / отложено (бюджет) | deferred by owner decision / deferred (budget) |
| проведено в очереди <дата> | done in queue <date> |
| (предположение) | (assumption) |
| ссылки на поля CONFIG | `CONFIG.Main branch`, `CONFIG.Target branch`, `CONFIG.Autonomy level`, `CONFIG.Fix threshold`, `CONFIG.Parallelism`, `CONFIG.Time budget`, `CONFIG.Reviews`, `CONFIG.Push` |
| сообщения коммитов | `revref(W0): run initialization`, `revref(state): checkpoint W<n>/<step>`, `revref(wip): <ID> — done: …; remaining: …`, `revref(finish): processed owner decisions`, `revref: run result <date> — <one-line summary>` |
