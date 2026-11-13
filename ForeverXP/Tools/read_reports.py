"""Turns the player's ForeverXP saved variables into a route fix list.

Run:  python Tools/read_reports.py <path to ForeverXP.lua> [out.md]
  The file is WTF/Account/<ACCOUNT>/SavedVariables/ForeverXP.lua in the WoW folder (written on /reload or logout).
  Prints Markdown (or writes it to out.md): step reports, slow/skipped/deadly steps from the run log, and the
  in-game route check, each pointing at the guide file and line (via Tools/dev/guides.json from audit_parse.py).
"""
import json
import os
import re
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))


# ---------------------------------------------------------------------------
# Minimal parser for WoW SavedVariables (a subset of Lua table constructors)
# ---------------------------------------------------------------------------
TOKEN = re.compile(r'''
    (?P<ws>\s+|--\[\[.*?\]\]|--[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*")
  | (?P<num>-?(?:0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+))
  | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<sym>[{}\[\]=,;])
''', re.X | re.S)

ESC = {'n': '\n', 't': '\t', 'r': '\r', '\\': '\\', '"': '"', "'": "'", '\n': '\n', 'a': '\a', 'b': '\b'}


def unquote(s):
    out, i = [], 1
    while i < len(s) - 1:
        c = s[i]
        if c == '\\':
            n = s[i + 1]
            if n.isdigit():
                m = re.match(r'\d{1,3}', s[i + 1:])
                out.append(chr(int(m.group()))); i += 1 + len(m.group()); continue
            out.append(ESC.get(n, n)); i += 2; continue
        out.append(c); i += 1
    return ''.join(out)


def tokens(text):
    pos = 0
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            raise ValueError('cannot parse near: ' + text[pos:pos + 40])
        pos = m.end()
        kind = m.lastgroup
        if kind != 'ws':
            yield kind, m.group()


class Parser:
    def __init__(self, text):
        self.t = list(tokens(text)); self.i = 0

    def peek(self): return self.t[self.i] if self.i < len(self.t) else (None, None)

    def take(self, want=None):
        k, v = self.peek(); self.i += 1
        if want and v != want: raise ValueError(f'expected {want}, got {v}')
        return k, v

    def value(self):
        k, v = self.take()
        if k == 'str': return unquote(v)
        if k == 'num': return int(v, 16) if v.lower().startswith(('0x', '-0x')) else (float(v) if re.search(r'[.eE]', v) else int(v))
        if k == 'name': return {'true': True, 'false': False, 'nil': None}.get(v, v)
        if v == '{': return self.table()
        raise ValueError('unexpected ' + str(v))

    def table(self):
        arr, d, n = [], {}, 0
        while True:
            k, v = self.peek()
            if v == '}': self.take(); break
            if v == '[':
                self.take(); key = self.value(); self.take(']'); self.take('='); d[key] = self.value()
            elif k == 'name' and self.t[self.i + 1][1] == '=':
                self.take(); self.take('='); d[v] = self.value()
            else:
                n += 1; arr.append(self.value())
            if self.peek()[1] in (',', ';'): self.take()
        if d and arr:
            for j, x in enumerate(arr, 1): d[j] = x
            return d
        if d and all(isinstance(x, int) for x in d) and sorted(d) == list(range(1, len(d) + 1)):
            return [d[j] for j in range(1, len(d) + 1)]
        return d if d else arr


def load_saved_variables(path):
    text = open(path, encoding='utf-8', errors='replace').read()
    p, out = Parser(text), {}
    while p.peek()[0]:
        _, name = p.take(); p.take('='); out[name] = p.value()
    return out


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
def guide_lines():
    path = os.path.join(HERE, 'dev', 'guides.json')
    try:
        guides = json.load(open(path))
    except OSError:
        return {}
    out = {}
    for g in guides:
        for i, s in enumerate(g['steps'], 1):
            out[(g['name'], i)] = (g.get('file'), s.get('_line'))
    return out


def where(lines, guide, src):
    """`src` is the step's position in the guide file (the addon injects class quest steps at runtime, so the
    in-game step number can be higher). Class quest steps have no src: they live in Data/ClassQuests.lua."""
    if src is None:
        return '(class quest step, Data/ClassQuests.lua)'
    f, line = lines.get((guide, src), (None, None))
    if line:
        return f'`{f}:{line}`' if f else f'line {line}'
    return ''


def as_list(x):
    if x is None: return []
    return x if isinstance(x, list) else list(x.values()) if isinstance(x, dict) else [x]


def build(sv):
    db = sv.get('ForeverXPDB') or {}
    lines = guide_lines()
    md = ['# ForeverXP route feedback', '', f'Installed version at last login: {db.get("lastVersion", "not recorded (before 2.12.2)")}', '']

    reports = as_list(db.get('reports'))
    md += [f'## Reports ({len(reports)})', '']
    by_step = defaultdict(list)
    for r in reports:
        by_step[(r.get('guide'), r.get('step'), r.get('src'))].append(r)
    for (g, st, src), rs in sorted(by_step.items(), key=lambda kv: (str(kv[0][0]), kv[0][1] or 0)):
        md.append(f'### {g} #{st} {where(lines, g, src)}')
        md.append(f'> {rs[0].get("text", "")}')
        for r in rs:
            w = r.get('where') or {}
            md.append(f'- **{r.get("reason")}** (v{r.get("version")}, level {r.get("level")} {r.get("race", "")} {r.get("class", "")}, '
                      f'{w.get("zone", "")} {w.get("sub", "")} {w.get("x", "?")},{w.get("y", "?")}): {r.get("note") or "(no note)"}')
            for q in as_list(r.get('quests')):
                state = [k for k in ('onQuest', 'complete', 'turnedIn', 'unavailable') if q.get(k)]
                md.append(f'  - {q.get("kind")} {q.get("quest")} (id {q.get("id")}): {", ".join(state) or "not started"}')
        md.append('')

    log = as_list(db.get('runLog'))
    stats = defaultdict(lambda: {'n': 0, 'secs': 0, 'skipped': 0, 'deaths': 0})
    for e in log:
        k = (e.get('guide'), e.get('step'), e.get('src'))
        s = stats[k]
        s['n'] += 1; s['secs'] += e.get('secs') or 0; s['deaths'] += e.get('deaths') or 0
        if e.get('how') != 'done': s['skipped'] += 1
    bad = [(k, s) for k, s in stats.items() if s['secs'] / s['n'] > 600 or s['skipped'] or s['deaths']]
    bad.sort(key=lambda kv: -(kv[1]['deaths'] * 600 + kv[1]['skipped'] * 300 + kv[1]['secs'] / kv[1]['n']))
    total = sum(s['secs'] for s in stats.values())
    md += [f'## Run log ({len(log)} steps, {total // 3600}h {total % 3600 // 60}m played on the route)', '']
    md += ['| Step | Avg time | Skipped | Deaths | Where |', '|---|---|---|---|---|']
    for (g, st, src), s in bad[:60]:
        md.append(f'| {g} #{st} | {s["secs"] / s["n"] / 60:.0f} min | {s["skipped"]}/{s["n"]} | {s["deaths"]} | {where(lines, g, src)} |')
    md.append('')

    rc = db.get('routeCheck') or {}
    findings = as_list(rc.get('findings'))
    md += [f'## Route check ({rc.get("when", "not run")}, v{rc.get("version", "?")}: {len(findings)} findings)', '']
    by_issue = defaultdict(list)
    for f in findings:
        kind = re.sub(r'\d+(\.\d+)?', 'N', f.get('issue', ''))[:60]
        by_issue[kind].append(f)
    for kind, fs in sorted(by_issue.items(), key=lambda kv: -len(kv[1])):
        md.append(f'### {kind} ({len(fs)})')
        for f in fs:
            md.append(f'- {f.get("guide")} #{f.get("step")} {where(lines, f.get("guide"), f.get("src"))} '
                      f'{f.get("quest") or ""}: {f.get("issue")}')
        md.append('')
    return '\n'.join(md)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    text = build(load_saved_variables(sys.argv[1]))
    if len(sys.argv) > 2:
        open(sys.argv[2], 'w').write(text); print('wrote', sys.argv[2])
    else:
        print(text)
