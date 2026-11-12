import json,re,collections
G=json.load(open('Tools/dev/guides.json'))
KNOWN={'accept','complete','turnin','text','coords','radius','warn','tip','optional','train','zone','level','npc','elite','group','ifLevel','noArrow','xp','_line','mount','races','class','anyQuest','fly','fp','bind','hearth','target','useItem'}
by={g['name']:g for g in G}
def L(x): return x if isinstance(x,list) else [x]
issues=collections.defaultdict(list)
# chain
cur='Northshire 1-6';seen=[];
while cur: seen.append(cur); cur=by[cur].get('next')
print('MAIN CHAIN:', ' -> '.join(seen)); print('not in chain:',[g['name'] for g in G if g['name'] not in seen])
for a,b in zip(seen,seen[1:]):
    if by[a]['maxLevel']!=by[b]['minLevel']: issues['chain'].append(f'{a} max {by[a]["maxLevel"]} vs {b} min {by[b]["minLevel"]}')
accepted=set();turned=set();completed=set()
for gname in seen+[g['name'] for g in G if g['name'] not in seen]:
    g=by[gname]; lastlvl=0
    if g.get('faction')!='Alliance': issues[gname].append('faction '+str(g.get('faction')))
    for i,s in enumerate(g['steps'],1):
        tag=f'{gname} #{i} (line {s.get("_line")})'
        unk=set(s)-KNOWN
        if unk: issues['unknown keys'].append(f'{tag}: {unk}')
        kinds=[k for k in('accept','complete','turnin','level','train') if k in s]
        if len(kinds)>1: issues['multi-kind'].append(f'{tag}: {kinds}')
        if not kinds and 'text' not in s: issues['empty'].append(tag)
        c=s.get('coords')
        if c is not None:
            if not(isinstance(c,list) and len(c)==2 and all(0<=v<=100 for v in c)): issues['coords'].append(f'{tag}: {c}')
        if 'level' in s:
            lv=s['level']
            if lv<lastlvl: issues['level order'].append(f'{tag}: level {lv} after {lastlvl}')
            if not(g['minLevel']<=lv<=g['maxLevel']+1): issues['level range'].append(f'{tag}: level {lv} outside {g["minLevel"]}-{g["maxLevel"]}')
            lastlvl=max(lastlvl,lv)
        for q in L(s.get('accept',[])): accepted.add(q)
        for q in L(s.get('complete',[])):
            if q not in accepted and not isinstance(q,(int,float)): issues['complete before accept'].append(f'{tag}: {q}')
            completed.add(q)
        for q in L(s.get('turnin',[])):
            if q not in accepted and not isinstance(q,(int,float)): issues['turnin w/o accept (ok if item-started/carried)'].append(f'{tag}: {q}')
            if q in turned: issues['double turnin'].append(f'{tag}: {q}')
            turned.add(q)
        for k in ('warn','tip','text'):
            if k in s and (not isinstance(s[k],str) or not s[k].strip()): issues['bad text'].append(f'{tag}: {k}')
        if 'warn' in s and 'tip' not in s: issues['warn w/o tip'].append(tag)
        if s.get('train') and not s.get('zone'): issues['train no zone'].append(tag)
never=[q for q in accepted if q not in turned]
issues['accepted, never turned in']=sorted(map(str,never))
for k,v in issues.items():
    if v: print(f'\n== {k} ({len(v)})'); [print('  ',x) for x in v]
