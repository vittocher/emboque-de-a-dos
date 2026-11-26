"""Alcance de saltos: qué repisas se alcanzan desde cuáles (para diseñar recorridos y buscar atajos).

Lee un nivel, simula el salto del jugador (misma física que player.gd; la cuerda no cambia el salto) y arma el grafo
de repisas (bloques). No conoce plataformas móviles, ganchos, cajas, viento ni al emboque; las compuertas cuentan
como cerradas. Tarda ~10 s por nivel.

    python tests/reach.py NIVEL X0,PISO0 X1,PISO1 [X0,PISO0 X1,PISO1 ...]

Imprime el camino de saltos de una repisa a otra en el formato de M.path (tests/solutions/moves.gd) y el margen de
cada salto (px de despegue que sirven; con menos de ~20 es muy justo), o lo que sí se alcanza si no hay camino.
Si cambian jump_velocity / speed / aceleraciones en player.gd, cambiarlas también acá.
"""
import re, sys, math, heapq
from collections import deque
V = 470.; G = 980.; SP = 320.; ACC = 2200.; FR = 2600.; AIR = .5; DT = 1 / 120.
HW, HH = 20., 32.


def load(n, caca=False, skip=()):
    p = n if n.endswith('.tscn') else (f'scenes/{n}.tscn' if n.startswith('level_') else f'scenes/levels/{n}.tscn')
    t = open(p, encoding='utf8').read().replace('\r\n', '\n')
    ids = {i: k.split('/')[-1].split('.')[0] for k, i in re.findall(r'path="res://([^"]+)"[^\]]*id="([^"]+)"', t)}
    sol = []; kil = []
    def f(s, d):
        return [float(x) for x in re.findall(r'-?[\d.]+', s.replace('Vector2', ''))] if s else d
    for q in re.split(r'\n\n(?=\[node)', t)[1:]:
        m = re.match(r'\[node name="([^"]+)"(?:.*?ExtResource\("([^"]+)"\))?', q)
        nm = m.group(1); k = ids.get(m.group(2) or '', '-')
        if nm in skip: continue
        pr = dict(re.findall(r'^(\w+) = (.+)$', q, re.M))
        pos = f(pr.get('position', ''), [0, 0])
        sz = f(pr.get('size', '') if 'Vector2' in pr.get('size', '') else '', None)
        sc = f(pr.get('scale', ''), [1, 1]); rot = float(pr.get('rotation', '0'))
        if k in ('block', 'gate') and sz:
            sol.append((pos[0] - sz[0] / 2, pos[1] - sz[1] / 2, pos[0] + sz[0] / 2, pos[1] + sz[1] / 2, nm))
        if k in ('player_death_zone', 'both_death_zone') or (caca and k == 'emboque_death_zone'):
            w, h = 100 * sc[0], 30 * sc[1]
            if abs(abs(rot) - 1.5708) < .1: w, h = h, w
            kil.append((pos[0] - w / 2, pos[1] - h / 2, pos[0] + w / 2, pos[1] + h / 2, nm))
    W = 1600 if 'base_large' in t else 1280
    sol.append((-60, -2000, 0, 2000, 'WL')); sol.append((W, -2000, W + 60, 2000, 'WR'))
    return sol, kil


def hit(r, x, y, e=0.01):
    return x + HW > r[0] + e and x - HW < r[2] - e and y + HH > r[1] + e and y - HH < r[3] - e


def step_free(sol, x, y, vx, vy):
    nx = x + vx * DT
    for r in sol:
        if hit(r, nx, y):
            nx = r[0] - HW if vx > 0 else r[2] + HW; vx = 0
    ny = y + vy * DT; floor = None
    for r in sol:
        if hit(r, nx, ny):
            if vy >= 0: ny = r[1] - HH; floor = r[4]
            else: ny = r[3] + HH
            vy = 0
    return nx, ny, vx, vy, floor


def walkctl(x, vx, tx, tol, air):
    dx = tx - x; c = AIR if air else 1; sd = vx * vx / (2 * FR * c)
    tow = (vx > 0) == (dx > 0) and abs(vx) > 5
    if abs(dx) > tol and not (tow and abs(dx) <= sd + tol * .5): return 1 if dx > 0 else -1
    return 0


def accel(vx, d, air):
    c = AIR if air else 1
    if d: t = d * SP; a = ACC * c * DT
    else: t = 0; a = FR * c * DT
    return vx + max(-a, min(a, t - vx))


def sim(sol, kil, x, top, tx, jump, runup=25, d=None):
    y = top - HH; d = d or (1 if tx > x else -1)
    vx = d * min(SP, math.sqrt(2 * ACC * runup)) if runup > 0 else 0
    vy = -V if jump else 0; t = 0; air = jump
    while t < 3:
        c = walkctl(x, vx, tx, 4, True) if jump else walkctl(x, vx, tx, 5, air)
        vx = accel(vx, c, air)
        vy += G * DT
        x, y, vx, vy, fl = step_free(sol, x, y, vx, vy)
        if y > 1000: return None, x, 'cae'
        for k in kil:
            if hit(k, x, y): return None, x, k[4]
        if fl and abs(y + HH - top) < .5 and not jump:
            # sigue caminando por la repisa de salida
            if abs(x - tx) < 6 and abs(vx) < 10: return fl, x, 'ok'
            air = False; t += DT; continue
        if fl and (t > .1): return fl, x, 'ok'
        air = fl is None; t += DT
    return None, x, 'tiempo'


def segs(sol, kil):
    out = []
    for r in sol:
        if r[4] in ('WL', 'WR') or r[2] - r[0] < 14: continue
        xs = []; x = r[0] - 14
        while x <= r[2] + 14:
            ok = x >= 20 and not any(hit(o, x, r[1] - HH - .5) for o in sol if o is not r) and not any(hit(k, x, r[1] - HH) for k in kil)
            xs.append((x, ok)); x += 4
        cur = []
        for x, ok in xs + [(0, False)]:
            if ok: cur.append(x)
            else:
                if len(cur) >= 3: out.append((r[4], r[1], cur[0], cur[-1]))
                cur = []
    return out


def graph(sol, kil, S=None):
    S = S or segs(sol, kil); E = {}
    for i, a in enumerate(S):
        for j, b in enumerate(S):
            if i == j or a[1] - b[1] > 116: continue
            ba = (b[2] + b[3]) / 2
            gap = max(b[2] - a[3], a[2] - b[3])
            if gap > 370: continue
            best = None
            for d in (1, -1):
                for jump in (True, False):
                    near = b[2] + 20 if d > 0 else b[3] - 20
                    for tx in {ba, near}:
                        xs = []; x = a[2] + 2
                        while x <= a[3] - 2:
                            room = (x - a[2]) if d > 0 else (a[3] - x)
                            ok = False
                            if room >= 8 and (tx - x) * d > 0:
                                fl, lx, why = sim(sol, kil, x, a[1], tx, jump, min(25, room), d)
                                ok = fl == b[0] and b[2] - 2 <= lx <= b[3] + 2
                            xs.append((x, ok)); x += 5
                        run = []; cur = []
                        for x, ok in xs + [(0, False)]:
                            if ok: cur.append(x)
                            else:
                                if len(cur) > len(run): run = cur
                                cur = []
                        if run:
                            m = run[-1] - run[0]
                            cost = 1 / (1 + m / 10) + (0 if jump else -.02)
                            if best is None or cost < best[0]: best = (cost, jump, round(run[len(run) // 2]), round(tx), m)
            if best: E[(i, j)] = best
    return S, E


def find(S, x, top):
    c = [i for i, s in enumerate(S) if abs(s[1] - top) < 3 and s[2] - 20 <= x <= s[3] + 20]
    if not c: raise SystemExit(f'no hay repisa en {x},{top}: ' + str([s for s in S if abs(s[1] - top) < 60]))
    return c[0]


def route(S, E, a, b, minm=10):
    D = {a: (0, None)}; Q = [(0, a)]
    while Q:
        d, u = heapq.heappop(Q)
        if u == b: break
        if d > D[u][0]: continue
        for (i, j), e in E.items():
            if i == u and e[4] >= minm:
                nd = d + 1 + e[0]
                if j not in D or nd < D[j][0]: D[j] = (nd, u); heapq.heappush(Q, (nd, j))
    if b not in D: return None
    p = [b]
    while p[-1] != a: p.append(D[p[-1]][1])
    return p[::-1]


def fmt(S, E, p):
    out = []
    for i, j in zip(p, p[1:]):
        e = E[(i, j)]
        out.append(f'[{e[2]}, {e[3]}]' if e[1] else f'["go", {e[3]}]')
    return '[' + ', '.join(out) + ']'


def reach(E, i, minm=0):
    seen = {i}; q = deque([i])
    while q:
        u = q.popleft()
        for (s, t), e in E.items():
            if s == u and t not in seen and e[4] >= minm: seen.add(t); q.append(t)
    return seen


def main():
    n = sys.argv[1]; sol, kil = load(n); S, E = graph(sol, kil)
    for a in range(2, len(sys.argv) - 1, 2):
        (x0, y0), (x1, y1) = [map(float, v.split(',')) for v in sys.argv[a:a + 2]]
        i, j = find(S, x0, y0), find(S, x1, y1); p = route(S, E, i, j)
        if not p:
            print('SIN CAMINO desde', S[i][0], 'a', S[j][0], '| alcanza:', [f'{S[k][0]}@{S[k][1]:.0f}:{S[k][2]:.0f}-{S[k][3]:.0f}' for k in sorted(reach(E, i))]); continue
        print(' > '.join(S[k][0] for k in p), '| margenes', [int(E[(u, v)][4]) for u, v in zip(p, p[1:])]); print('  ', fmt(S, E, p))


if __name__ == '__main__': main()
