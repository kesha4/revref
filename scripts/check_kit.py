#!/usr/bin/env python3
"""Self-check of the RevRef kit: references, structure, versions, language parity.

Usage: python scripts/check_kit.py   (exit code 0 — all checks passed)
Checks:
  - every kit file referenced in backticks (prompts/…, templates/…, roles/…, hooks/…, top-level *.md) exists;
  - every "§N" reference to PROTOCOLS.md has a matching "## §N." heading;
  - review IDs agree: prompt files, the wave table in PIPELINE.md, the QR applicability list, both READMEs;
  - VERSION agrees with the top entry of both changelogs; both language trees have the same VERSION;
  - the Russian and English trees have the same files, the same §-sections and the same code-fence counts;
  - SKILL.md and agents carry the guard hook placeholder; relative links in READMEs resolve;
  - install.ps1 starts with a UTF-8 BOM (Windows PowerShell 5.1 needs it for non-ASCII text).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TREES = {'ru': (ROOT / 'skill' / 'revref', ROOT / 'agents', ROOT / 'CHANGELOG.md', ROOT / 'README.md'),
         'en': (ROOT / 'skill-en' / 'revref', ROOT / 'agents-en', ROOT / 'CHANGELOG.en.md', ROOT / 'README.en.md')}
BUILTIN_IDS = ['QR', 'SEC', 'DEP', 'BUG', 'DATA', 'EDGE', 'RES', 'TEST', 'DX', 'HYG', 'ARC', 'DEC', 'DRY',
               'PERF', 'OBS', 'API', 'I18N', 'RWD', 'A11Y', 'CMT', 'SPEC', 'UDOC']
AGENTS = ['revref-reviewer.md', 'revref-verifier.md', 'revref-fixer.md']
PLACEHOLDER = '__REVREF_SKILL_DIR__'
KIT_REF = re.compile(r'`((?:prompts|templates|roles|hooks)/[A-Za-z0-9_./<>-]+|'
                     r'(?:ORCHESTRATOR|PIPELINE|POLICY|PROTOCOLS|SKILL)\.md|VERSION)`')
SECTION_REF = re.compile(r'PROTOCOLS\.md`?\s*§\s*(\d+)|§\s*(\d+)')

errors = []


def err(msg):
    errors.append(msg)


def read(path):
    return path.read_text(encoding='utf-8')


def md_files(base):
    return sorted(p for p in base.rglob('*') if p.is_file())


def check_tree(lang, skill, agents, changelog, readme):
    if not skill.is_dir():
        err(f'[{lang}] нет каталога скилла {skill.relative_to(ROOT)}')
        return None
    # References to kit files
    for f in md_files(skill):
        if f.suffix != '.md':
            continue
        text = read(f)
        for m in KIT_REF.finditer(text):
            ref = m.group(1)
            if '<' in ref:  # template like prompts/reviews/<ID>.md
                pattern = re.sub(r'<[^>]+>', '*', ref)
                if not list(skill.glob(pattern)):
                    err(f'[{lang}] {f.relative_to(ROOT)}: шаблон ссылки `{ref}` не совпадает ни с одним файлом')
            elif not (skill / ref).exists():
                err(f'[{lang}] {f.relative_to(ROOT)}: ссылка на несуществующий файл `{ref}`')
    # § references
    protocols = read(skill / 'PROTOCOLS.md')
    sections = set(re.findall(r'^## §(\d+)\.', protocols, re.M))
    for f in md_files(skill):
        if f.suffix != '.md':
            continue
        for m in SECTION_REF.finditer(read(f)):
            n = m.group(1) or m.group(2)
            if n not in sections:
                err(f'[{lang}] {f.relative_to(ROOT)}: ссылка на §{n}, а в PROTOCOLS.md есть только §{", §".join(sorted(sections, key=int))}')
    # Review IDs
    ids = sorted(p.stem for p in (skill / 'prompts' / 'reviews').glob('*.md'))
    if sorted(ids) != sorted(BUILTIN_IDS):
        err(f'[{lang}] набор промптов ревью {ids} не совпадает с ожидаемым {sorted(BUILTIN_IDS)}')
    pipeline = read(skill / 'PIPELINE.md')
    table = pipeline.split('\n## ', 2)[1] if '\n## ' in pipeline else pipeline
    for rid in BUILTIN_IDS:
        if not re.search(rf'\b{re.escape(rid)}\b', table):
            err(f'[{lang}] PIPELINE.md: ревью {rid} отсутствует в таблице волн')
    qr = read(skill / 'prompts' / 'reviews' / 'QR.md')
    for rid in BUILTIN_IDS[1:]:
        if not re.search(rf'\b{re.escape(rid)}\b', qr):
            err(f'[{lang}] QR.md: ревью {rid} отсутствует в матрице применимости')
    for rid in BUILTIN_IDS:
        if readme.exists() and f'`{rid}`' not in read(readme):
            err(f'[{lang}] {readme.name}: ревью {rid} нет в полном списке ID')
    for rid in ids:
        head = read(skill / 'prompts' / 'reviews' / f'{rid}.md').splitlines()[0]
        if not head.startswith(f'# {rid} '):
            err(f'[{lang}] prompts/reviews/{rid}.md: первая строка должна начинаться с «# {rid} »')
    # Version
    version = read(skill / 'VERSION').strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        err(f'[{lang}] VERSION: «{version}» — не семантическая версия')
    if changelog.exists():
        top = re.search(r'^## (\d+\.\d+\.\d+)', read(changelog), re.M)
        if not top or top.group(1) != version:
            err(f'[{lang}] {changelog.name}: верхняя запись {top.group(1) if top else "—"} ≠ VERSION {version}')
    else:
        err(f'[{lang}] нет {changelog.name}')
    # Guard placeholder
    for f in [skill / 'SKILL.md'] + [agents / a for a in AGENTS]:
        if not f.exists():
            err(f'[{lang}] нет файла {f.relative_to(ROOT)}')
        elif PLACEHOLDER not in read(f) or 'hooks/guard.sh' not in read(f):
            err(f'[{lang}] {f.relative_to(ROOT)}: во frontmatter нет хука guard с {PLACEHOLDER}')
    if not (skill / 'hooks' / 'guard.sh').exists():
        err(f'[{lang}] нет hooks/guard.sh')
    # README relative links
    if readme.exists():
        for target in re.findall(r'\]\(([^)#:]+)(?:#[^)]*)?\)', read(readme)):
            if not (ROOT / target).exists():
                err(f'[{lang}] {readme.name}: битая ссылка ({target})')
    else:
        err(f'[{lang}] нет {readme.name}')
    return {'version': version, 'files': {str(p.relative_to(skill)) for p in md_files(skill)},
            'sections': sections, 'skill': skill}


def fences(path):
    return sum(1 for line in read(path).splitlines() if line.lstrip().startswith('```'))


results = {lang: check_tree(lang, *paths) for lang, paths in TREES.items()}
ru, en = results.get('ru'), results.get('en')
if ru and en:
    if ru['version'] != en['version']:
        err(f'VERSION различается: ru {ru["version"]}, en {en["version"]}')
    if ru['files'] != en['files']:
        err(f'наборы файлов различаются: только ru {sorted(ru["files"] - en["files"])}, только en {sorted(en["files"] - ru["files"])}')
    if ru['sections'] != en['sections']:
        err(f'разделы § в PROTOCOLS.md различаются: ru {sorted(ru["sections"])}, en {sorted(en["sections"])}')
    for rel in sorted(ru['files'] & en['files']):
        a, b = ru['skill'] / rel, en['skill'] / rel
        if a.suffix == '.md' and fences(a) != fences(b):
            err(f'{rel}: число блоков кода ru {fences(a)} ≠ en {fences(b)}')
    guard_ru, guard_en = (ru['skill'] / 'hooks' / 'guard.sh'), (en['skill'] / 'hooks' / 'guard.sh')
    if guard_ru.exists() and guard_en.exists() and read(guard_ru) != read(guard_en):
        err('hooks/guard.sh различается в ru и en — хук общий, файлы должны совпадать')
    for a in AGENTS:
        ra, ea = ROOT / 'agents' / a, ROOT / 'agents-en' / a
        if ra.exists() and ea.exists():
            name_ru = re.search(r'^name:\s*(\S+)', read(ra), re.M)
            name_en = re.search(r'^name:\s*(\S+)', read(ea), re.M)
            if not name_ru or not name_en or name_ru.group(1) != name_en.group(1):
                err(f'agents: у {a} разные name в ru и en')

ps1 = ROOT / 'install.ps1'
if not ps1.read_bytes().startswith(b'\xef\xbb\xbf'):
    err('install.ps1: нет UTF-8 BOM — Windows PowerShell 5.1 исказит кириллицу')

if errors:
    print(f'check_kit: ошибок {len(errors)}')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print(f'check_kit: OK (версия {ru["version"] if ru else "?"}, файлов в скилле: {len(ru["files"]) if ru else 0})')
