import ctypes,sys
L=ctypes.CDLL('/usr/lib/x86_64-linux-gnu/liblua5.4.so.0')
L.luaL_newstate.restype=ctypes.c_void_p
L.lua_tolstring.restype=ctypes.c_char_p
L.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
L.luaL_openlibs.argtypes=[ctypes.c_void_p]
L.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
L.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
L.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_void_p,ctypes.c_void_p]
def state():
    s=L.luaL_newstate(); L.luaL_openlibs(s); return s
mode=sys.argv[1]
if mode=='check':
    bad=0
    for f in sys.argv[2:]:
        s=state()
        if L.luaL_loadfilex(s,f.encode(),None)!=0:
            print('SYNTAX',L.lua_tolstring(s,-1,None).decode()); bad+=1
    print('compiled',len(sys.argv)-2,'files,',bad,'errors')
else:
    s=state()
    if L.luaL_loadfilex(s,sys.argv[2].encode(),None)!=0 or L.lua_pcallk(s,0,0,0,None,None)!=0:
        print('ERROR',L.lua_tolstring(s,-1,None).decode())
