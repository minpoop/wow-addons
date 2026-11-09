import json
G=json.load(open('Tools/dev/guides.json'));by={g['name']:g for g in G}
def L(x): return x if isinstance(x,list) else [x]
cur='Northshire 1-6';log=set();peak=(0,'')
places=['Gadgetzan','Steamwheedle','Ironforge','Stormwind','Darnassus','Auberdine','Menethil','Booty Bay','Theramore','Goldshire','Lakeshire','Sentinel Hill','Darkshire','Thelsamar','Refuge Pointe','Astranaar','Everlook','Southshore','Ratchet','Aerie Peak','Rut\'theran']
while cur:
    g=by[cur]
    for i,s in enumerate(g['steps'],1):
        for q in L(s.get('accept',[])): log.add(q)
        for q in L(s.get('turnin',[])): log.discard(q)
        if len(log)>peak[0]: peak=(len(log),f'{cur} #{i}')
        if 'coords' in s and 'zone' not in s:
            t=s.get('text','')
            hits=[p for p in places if p in t]
            if hits: print('ZONE?',cur,'#',i,'line',s.get('_line'),hits,'|',t[:90])
    print(f'{cur:30s} log after: {len(log)}')
    cur=g.get('next')
print('PEAK',peak)
