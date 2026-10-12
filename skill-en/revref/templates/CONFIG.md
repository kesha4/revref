# RevRef run settings

This file is filled in by the owner. On `init` the agent creates a draft: it asks up to 5 questions, determines the rest itself and marks it "(assumption)". Changes made during a run take effect at the boundary of the next wave step.

## Project

- Purpose and users:
- Stage: prototype / MVP / production / legacy
- Load and data volume:
- Critical parts (money, personal data, access):
- Do not touch:
- Special focus:

## Run

- Autonomy level: balanced                 <!-- cautious | balanced | bold — see POLICY.md -->
- Fix threshold: Medium                    <!-- Critical | High | Medium | Low; below the threshold — quick wins only -->
- Reviews: all applicable                  <!-- force include: … ; exclude: … -->
- Custom reviews: none                     <!-- ID → wave, e.g.: VPN → W2, GDPR → W8; files — .revref/reviews/<ID>.md (PIPELINE.md → "Custom reviews") -->
- Scope: whole repository                  <!-- include paths: … ; exclude paths: … -->
- Parallelism: up to 4 subagents
- Time budget: unlimited                   <!-- e.g.: 3 days, or until 2026-10-20 -->
- Run branch: revref/YYYY-MM-DD
- Main branch: main                        <!-- the run's base; the agent never changes it -->
- Target branch (finish): test             <!-- where finish merges the result; usually synced with the test stand -->
- Push: forbidden                          <!-- forbidden | allowed for the run branch only; pushing the target branch is always a separate question in finish -->
- Merge method (finish): ask               <!-- ask | merge --no-ff | squash | pull request -->
- .revref/ on merge (finish): ask          <!-- ask | keep | archive to docs/revref/<date>/ | remove; note: everything in the target branch will also go into the main branch -->
- Keep .revref/ in git: yes                <!-- yes — recommended: resume on any machine and in any session -->
- Report language: English
