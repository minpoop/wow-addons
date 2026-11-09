import re,glob,json,sys
TOK=re.compile(r'\s+|--\[\[.*?\]\]|--[^\n]*|"((?:\\.|[^"\\])*)"|\'((?:\\.|[^\'\\])*)\'|(-?\d+(?:\.\d+)?)|([A-Za-z_][A-Za-z0-9_.:]*)|(\.\.\.|\[|\]|\{|\}|=|,|\(|\)|;|#|\.|\+|-|\*)',re.S)
def toks(s):
    out=[];i=0
    while i<len(s):
        m=TOK.match(s,i)
        if not m: raise SyntaxError(f'bad char at {s.count(chr(10),0,i)+1}: {s[i:i+30]!r}')
        i=m.end()
        line=s.count('\n',0,m.start())+1
        if m.group(1) is not None: out.append(('s',m.group(1),line))
        elif m.group(2) is not None: out.append(('s',m.group(2),line))
        elif m.group(3): out.append(('n',float(m.group(3)),line))
        elif m.group(4): out.append(('id',m.group(4),line))
        elif m.group(5): out.append(('p',m.group(5),line))
    return out
class P:
    def __init__(s,t): s.t=t;s.i=0
    def peek(s,k=0): return s.t[s.i+k] if s.i+k<len(s.t) else (None,None,0)
    def take(s,v=None):
        x=s.t[s.i]
        if v and x[1]!=v: raise SyntaxError(f'line {x[2]}: expected {v} got {x[1]!r}')
        s.i+=1;return x
    def val(s):
        k,v,l=s.peek()
        if v=='{': return s.table()
        s.take()
        if k=='id':
            if v in('nil','true','false'): return {'nil':None,'true':True,'false':False}[v]
            raise SyntaxError(f'line {l}: unexpected identifier {v}')
        return v
    def table(s):
        s.take('{');arr=[];d={};line=s.peek()[2]
        while s.peek()[1]!='}':
            k,v,l=s.peek()
            if k=='id' and s.peek(1)[1]=='=':
                s.take();s.take('=')
                if v in d: print(f'DUPKEY line {l}: {v}')
                d[v]=s.val()
            elif v=='[':
                s.take();key=s.val();s.take(']');s.take('=');d[key]=s.val()
            else: arr.append(s.val())
            if s.peek()[1] in(',',';'): s.take()
            elif s.peek()[1]!='}': raise SyntaxError(f'line {s.peek()[2]}: missing comma before {s.peek()[1]!r}')
        s.take('}')
        if d: d['_line']=line; 
        if arr and d: d['_arr']=arr; return d
        return d if d else arr
guides=[]
for f in sorted(glob.glob('Guides/*.lua')):
    t=toks(open(f).read()); p=P(t)
    while p.i<len(t):
        if str(p.peek()[1]).endswith('FXP:RegisterGuide'):
            p.take();p.take('(');name=p.take()[1];p.take(',');tb=p.table();p.take(')')
            tb['name']=name;tb['file']=f;guides.append(tb)
        else: p.i+=1
json.dump(guides,open('Tools/dev/guides.json','w'),indent=0)
print(len(guides),'guides parsed', sum(len(g['steps']) for g in guides),'steps')
