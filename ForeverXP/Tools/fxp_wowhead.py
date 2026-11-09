#!/usr/bin/env python3
"""
fxp_wowhead.py - build ForeverXP's quest database from Wowhead.

Run this on your own computer (it needs normal internet access). It reads the
ForeverXP guide files, looks every quest up on Wowhead, and writes
Data/QuestDB.lua with each quest's real ID, level, required level, XP reward,
quest giver / turn-in NPC and their map coordinates. The addon uses that file
for exact catch-up XP, quest IDs and arrow positions.

Usage (from the ForeverXP folder, or pass --addon):
    python Tools/fxp_wowhead.py                      # update Data/QuestDB.lua
    python Tools/fxp_wowhead.py --site classic       # use Wowhead Classic data
    python Tools/fxp_wowhead.py --zone 40            # list every quest in a zone (by Wowhead zone ID)
    python Tools/fxp_wowhead.py --refresh            # ignore the cache and re-download
    python Tools/fxp_wowhead.py --debug              # save raw pages to Tools/debug/ when parsing fails

Only the Python standard library is used. Requests are spaced out and cached
(Tools/fxp_cache.json) so a re-run only downloads what is new. Please keep it
that way: Wowhead is a free site, and their terms limit automated access, so
use this for your own addon data only.
"""

import argparse
import glob
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from html import unescape

HOST = "https://www.wowhead.com"
USER_AGENT = "Mozilla/5.0 (ForeverXP quest data tool; personal use)"
DELAY = 1.5  # seconds between requests


# --------------------------------------------------------------------------
# Fetching
# --------------------------------------------------------------------------
class Fetcher:
    def __init__(self, site, debug=False):
        self.base = HOST + ("/" + site.strip("/") if site else "")
        self.site = site
        self.debug = debug
        self.last = 0.0

    def url(self, path):
        return self.base + path

    def get(self, path):
        """Return (final_url, html) or (None, None) on failure."""
        wait = DELAY - (time.time() - self.last)
        if wait > 0:
            time.sleep(wait)
        self.last = time.time()
        req = urllib.request.Request(self.url(path), headers={"User-Agent": USER_AGENT})
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    return r.geturl(), r.read().decode("utf-8", "replace")
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return None, None
                if e.code in (429, 503):
                    time.sleep(10 * (attempt + 1))
                    continue
                print("  ! HTTP %s for %s" % (e.code, path))
                return None, None
            except Exception as e:  # network hiccup
                print("  ! %s for %s (retrying)" % (e, path))
                time.sleep(5)
        return None, None

    def dump(self, name, html):
        if not self.debug or not html:
            return
        d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "debug")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, name + ".html"), "w", encoding="utf-8") as f:
            f.write(html)


# --------------------------------------------------------------------------
# Parsing helpers
# --------------------------------------------------------------------------
def extract_bracketed(text, start):
    """Given text[start] == '[' or '{', return the balanced substring."""
    open_ch = text[start]
    close_ch = "]" if open_ch == "[" else "}"
    depth, i, in_str, quote = 0, start, False, ""
    while i < len(text):
        c = text[i]
        if in_str:
            if c == "\\":
                i += 1
            elif c == quote:
                in_str = False
        elif c in "\"'":
            in_str, quote = True, c
        elif c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
        i += 1
    return None


def loads_loose(s):
    """json.loads that tolerates the small JS-isms Wowhead uses."""
    try:
        return json.loads(s)
    except Exception:
        pass
    fixed = re.sub(r"([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:", r'\1"\2":', s)  # quote bare keys
    fixed = re.sub(r",\s*([}\]])", r"\1", fixed)                               # trailing commas
    fixed = fixed.replace("undefined", "null")
    try:
        return json.loads(fixed)
    except Exception:
        return None


def listview_data(html, lv_id):
    """Return the data array of `new Listview({id: '<lv_id>', ... data: [...]})`."""
    for m in re.finditer(r"new Listview\(", html):
        chunk = html[m.end():m.end() + 400]
        if not re.search(r"""id\s*:\s*['"]%s['"]""" % re.escape(lv_id), chunk):
            continue
        dm = re.search(r"data\s*:\s*\[", html[m.end():])
        if not dm:
            continue
        start = m.end() + dm.end() - 1
        arr = extract_bracketed(html, start)
        if arr:
            data = loads_loose(arr)
            if isinstance(data, list):
                return data
    return None


def markup_blocks(html):
    """Wowhead stores the Quick Facts box and other text as markup strings."""
    out = []
    for m in re.finditer(r"""(?:WH\.markup|Markup)\.printHtml\(\s*(["'])(.*?)(?<!\\)\1""", html, re.S):
        s = m.group(2)
        try:
            s = json.loads('"' + s.replace('"', '\\"').replace("\\'", "'") + '"') if m.group(1) == "'" else json.loads('"' + s + '"')
        except Exception:
            s = s.replace("\\/", "/").replace('\\"', '"')
        out.append(s)
    return out


def strip_tags(s):
    s = re.sub(r"<[^>]+>", "", s)
    s = re.sub(r"\[/?[a-z]+[^\]]*\]", "", s)
    return unescape(s).strip()


NPC_LINK = r"\[url=/?(?:[a-z-]+/)*npc=(\d+)[^\]]*\]([^\[]+)\[/url\]"


def parse_quest(html, qid):
    q = {"id": qid}
    m = re.search(r'<h1[^>]*class="[^"]*heading-size-1[^"]*"[^>]*>(.*?)</h1>', html, re.S) \
        or re.search(r'<meta property="og:title" content="([^"]+)"', html)
    if m:
        q["name"] = strip_tags(m.group(1))
    facts = "\n".join(markup_blocks(html))
    for key, pat in (("level", r"Level:\s*(\d+)"), ("req", r"Requires level\s*(\d+)")):
        m = re.search(pat, facts) or re.search(pat, strip_tags(html))
        if m:
            q[key] = int(m.group(1))
    m = re.search(r"Side:\s*(?:\[[^\]]*\])?\s*(Alliance|Horde|Both)", facts)
    if m:
        q["side"] = m.group(1)
    for key, label in (("start", "Start"), ("finish", "End")):
        m = re.search(label + r":\s*(?:\[icon[^\]]*\])?\s*" + NPC_LINK, facts)
        if m:
            q[key] = {"npc": int(m.group(1)), "name": unescape(m.group(2)).strip()}
    m = re.search(r"([\d,]+)\s+experience", html)
    if m:
        q["xp"] = int(m.group(1).replace(",", ""))
    return q


def parse_npc(html):
    """Return {'x':.., 'y':.., 'map':uiMapId, 'zone':name} from the NPC page's map data."""
    m = re.search(r"g_mapperData\s*=\s*", html)
    if m:
        start = m.end()
        blob = extract_bracketed(html, start) if html[start] in "[{" else None
        data = loads_loose(blob) if blob else None
        best = None

        def walk(o):
            nonlocal best
            if best:
                return
            if isinstance(o, dict):
                if o.get("coords"):
                    best = o
                    return
                for v in o.values():
                    walk(v)
            elif isinstance(o, list):
                for v in o:
                    walk(v)
        walk(data)
        if best:
            x, y = best["coords"][0][:2]
            return {"x": round(float(x), 1), "y": round(float(y), 1),
                    "map": best.get("uiMapId"), "zone": best.get("uiMapName")}
    m = re.search(r'"coords"\s*:\s*\[\[\s*([\d.]+)\s*,\s*([\d.]+)', html)
    if m:
        out = {"x": float(m.group(1)), "y": float(m.group(2))}
        mm = re.search(r'"uiMapId"\s*:\s*(\d+)', html)
        zm = re.search(r'"uiMapName"\s*:\s*"([^"]+)"', html)
        if mm:
            out["map"] = int(mm.group(1))
        if zm:
            out["zone"] = zm.group(1)
        return out
    return None


# --------------------------------------------------------------------------
# Guide scanning
# --------------------------------------------------------------------------
STR = r'"((?:[^"\\]|\\.)*)"'


def scan_guides(addon):
    ids, names = set(), set()
    for path in glob.glob(os.path.join(addon, "Guides", "*.lua")):
        src = open(path, encoding="utf-8").read()
        src = re.sub(r"--[^\n]*", "", src)
        for m in re.finditer(r"\b(accept|complete|turnin)\s*=\s*(\{[^}]*\}|" + STR + r"|\d+)", src):
            val = m.group(2)
            for n in re.findall(r"\b\d+\b", re.sub(STR, "", val)):
                ids.add(int(n))
            for s in re.findall(STR, val):
                names.add(s.replace('\\"', '"'))
        for m in re.finditer(r"\[(\d+)\]\s*=\s*" + STR, src):  # quests = { [id] = "Name" }
            ids.add(int(m.group(1)))
    return ids, names


# --------------------------------------------------------------------------
# Lua output
# --------------------------------------------------------------------------
def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def lua_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, dict):
        return "{ " + ", ".join("%s = %s" % (k, lua_val(x)) for k, x in v.items() if x is not None) + " }"
    return lua_str(v)


def write_db(path, quests, site):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lines = [
        "-- Generated by Tools/fxp_wowhead.py from Wowhead (%s) on %s. Do not edit by hand."
        % (site or "retail", time.strftime("%Y-%m-%d")),
        "local ADDON, ns = ...",
        "ns.QuestDB = {",
    ]
    for qid in sorted(quests):
        q = {k: v for k, v in quests[qid].items() if k != "id"}
        lines.append("  [%d] = %s," % (qid, lua_val(q)))
    lines.append("}")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
def load_cache(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_cache(path, cache):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(cache, f, indent=1)


def find_quest_id(fx, name, cache, faction):
    key = "search:" + name
    if key in cache:
        return cache[key]
    url, html = fx.get("/search?q=" + urllib.parse.quote(name))
    qid = None
    if url and "/quest=" in url:
        qid = int(re.search(r"quest=(\d+)", url).group(1))
    elif html:
        rows = listview_data(html, "quests") or []
        exact = [r for r in rows if strip_tags(str(r.get("name", ""))).lower() == name.lower()]
        # Wowhead "side": 1 = Alliance, 2 = Horde, 3 = both
        want = 1 if faction == "Alliance" else 2
        exact.sort(key=lambda r: 0 if r.get("side") in (want, 3, None) else 1)
        if exact:
            qid = int(exact[0]["id"])
        else:
            fx.dump("search_" + re.sub(r"\W+", "_", name), html)
    cache[key] = qid
    return qid


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--addon", default=os.path.dirname(here), help="path to the ForeverXP addon folder")
    ap.add_argument("--site", default="forever",
                    help="Wowhead section: forever (default), classic, or '' for retail")
    ap.add_argument("--faction", default="Alliance", choices=["Alliance", "Horde"])
    ap.add_argument("--zone", type=int, action="append", help="list all quests in a Wowhead zone ID instead")
    ap.add_argument("--refresh", action="store_true", help="ignore the cache")
    ap.add_argument("--debug", action="store_true", help="save pages that fail to parse to Tools/debug/")
    a = ap.parse_args()

    fx = Fetcher(a.site, a.debug)
    cache_path = os.path.join(here, "fxp_cache_%s.json" % (a.site or "retail"))
    cache = {} if a.refresh else load_cache(cache_path)

    # Quick connectivity / section check
    url, html = fx.get("/quest=783")
    if not html:
        print("Could not load %s/quest=783. If Wowhead's Forever section uses a different address,"
              " try --site classic, or check your internet connection." % fx.base)
        sys.exit(1)

    if a.zone:
        for z in a.zone:
            _, zhtml = fx.get("/zone=%d" % z)
            rows = listview_data(zhtml or "", "quests")
            if rows is None:
                fx.dump("zone_%d" % z, zhtml)
                print("Zone %d: couldn't read the quest list (use --debug and send me the file)." % z)
                continue
            print("\nZone %d: %d quests" % (z, len(rows)))
            for r in sorted(rows, key=lambda r: (r.get("level") or 0, r.get("name", ""))):
                side = {1: "A", 2: "H", 3: "AH"}.get(r.get("side"), "?")
                print("  %6s  lvl %-3s req %-3s %-3s xp %-6s %s" % (
                    r.get("id"), r.get("level", "?"), r.get("reqlevel", "?"), side, r.get("xp", "?"),
                    strip_tags(str(r.get("name", "")))))
        save_cache(cache_path, cache)
        return

    ids, names = scan_guides(a.addon)
    print("Guides reference %d quest IDs and %d quest names." % (len(ids), len(names)))

    missing = []
    for n in sorted(names):
        qid = find_quest_id(fx, n, cache, a.faction)
        if qid:
            ids.add(qid)
        else:
            missing.append(n)
        save_cache(cache_path, cache)

    quests, npc_ids = {}, set()
    for i, qid in enumerate(sorted(ids), 1):
        key = "quest:%d" % qid
        if key not in cache:
            _, qhtml = fx.get("/quest=%d" % qid)
            q = parse_quest(qhtml, qid) if qhtml else None
            if q and "name" not in q:
                fx.dump("quest_%d" % qid, qhtml)
            cache[key] = q
            save_cache(cache_path, cache)
        q = cache[key]
        if not q:
            print("  [%d/%d] quest %d: not found on this Wowhead section" % (i, len(ids), qid))
            continue
        quests[qid] = dict(q)
        for k in ("start", "finish"):
            if q.get(k):
                npc_ids.add(q[k]["npc"])
        print("  [%d/%d] %s (%s) xp=%s req=%s" % (i, len(ids), q.get("name", "?"), qid, q.get("xp"), q.get("req")))

    for nid in sorted(npc_ids):
        key = "npc:%d" % nid
        if key not in cache:
            _, nhtml = fx.get("/npc=%d" % nid)
            pos = parse_npc(nhtml) if nhtml else None
            if nhtml and not pos:
                fx.dump("npc_%d" % nid, nhtml)
            cache[key] = pos
            save_cache(cache_path, cache)

    for q in quests.values():
        for k in ("start", "finish"):
            if q.get(k):
                pos = cache.get("npc:%d" % q[k]["npc"])
                if pos:
                    q[k].update(pos)

    out = os.path.join(a.addon, "Data", "QuestDB.lua")
    write_db(out, quests, a.site)
    print("\nWrote %d quests to %s" % (len(quests), out))
    if missing:
        print("\nNo exact Wowhead match for %d quest names (check spelling in the guides):" % len(missing))
        for n in missing:
            print("  - " + n)


if __name__ == "__main__":
    main()
