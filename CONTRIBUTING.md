# Contributing to RevRef

Thanks for taking the time to improve RevRef. The project is a review-and-refactoring kit for coding agents: prompts, protocols, roles, installers and platform adapters. It runs real multi-day workloads, so correctness and safety matter more than speed of merging.

## Ways to contribute

- **Bug reports and feature requests** — use the issue templates. For questions and open-ended ideas, use [Discussions](https://github.com/kesha4/revref/discussions).
- **Real runs** — the `showcase` template. Real runs on real projects are the most useful feedback: what was found, what was false, what broke.
- **Documentation** — fixes, clarifications, examples, translations.
- **Code** — prompts, roles, installers, guard hook, tests.

## Before you open a pull request

1. Search existing issues and discussions to avoid duplicates.
2. Keep one topic per pull request. Large mixed changes are hard to review.
3. **Keep RU/EN parity.** A behaviour or wording change usually touches both trees:
   - `skill/revref/` and `skill-en/revref/`
   - `README.ru.md` and `README.md`
   - `CHANGELOG.md` and `CHANGELOG.en.md`
4. **No secrets.** Do not commit tokens, keys, passwords, personal data, client data or real production diffs. If you find a secret in the repository, report it privately (see [SECURITY.md](SECURITY.md)), do not open a public issue.
5. **AI-assisted contributions are welcome** if you disclose that and stand behind the result. Run the checks yourself; do not submit unreviewed generated code.
6. Do not change the `main` branch of a project that RevRef is running on — that rule is part of the product, not just this repository.

## Local checks

Run these before a pull request (from the repository root):

```bash
python3 scripts/check_kit.py        # structure, versions, RU/EN parity, README links
sh scripts/test_guard.sh            # guard hook
sh scripts/test_usage.sh            # status-line usage script
sh scripts/test_update.sh           # update script
sh scripts/test_install.sh          # installers
```

On Windows:

```powershell
py -3 scripts/check_kit.py
pwsh -File scripts/test_guard.ps1
./scripts/test_install.ps1
```

CI runs the same checks on Ubuntu, macOS and Windows. A pull request is expected to keep CI green.

## Adding a review type

1. Add `skill/revref/prompts/reviews/<ID>.md` and the English twin in `skill-en/revref/prompts/reviews/<ID>.md`.
2. Keep the ID 2–8 uppercase Latin letters/digits and distinct from the built-in list.
3. Add the review to the wave table in `PIPELINE.md` (both languages) and to the full list in both READMEs.
4. If the review needs a custom output format, add a template under `templates/` in both trees.
5. Run `scripts/check_kit.py`; it verifies that every review ID appears where expected.

## Commit messages

Short, imperative, scoped:

```text
docs: clarify DSH guard check in PLATFORMS.md
fix(guard): block git push --delete on main
feat(review): add MIG review prompt (RU/EN)
```

## Security

Please read [SECURITY.md](SECURITY.md) before reporting a vulnerability. Security reports must not be filed as public issues.

## License

By contributing, you agree that your contribution is distributed under the same license as the project: [CC BY 4.0](LICENSE). Attribution is required; note your changes if you redistribute a modified version.

## Code of conduct

Participation in this project is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
