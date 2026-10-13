"""Synthesises every sound effect and music loop (chiptune, no samples). usage: python3 tools/make_audio.py
SFX -> assets/sfx/*.wav   music -> assets/music/*.ogg (needs ffmpeg)"""
import numpy as np, wave, subprocess, os, random
SR = 24000
def midi(n): return 440.0 * 2 ** ((n - 69) / 12.0)
def wave_of(kind, ph, duty=0.5):
    f = ph % 1.0
    if kind == 'sq': return np.where(f < duty, 1.0, -1.0)
    if kind == 'tri': return 2 * np.abs(2 * f - 1) - 1
    if kind == 'saw': return 2 * f - 1
    return np.sin(2 * np.pi * ph)
def env(n, a=0.004, r=0.05, shape=1.0):
    e = np.ones(n); na = max(1, int(a * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na); e[-nr:] *= np.linspace(1, 0, min(nr, n))[:len(e[-nr:])]
    return e
def noise(n, seed=1): return np.random.RandomState(seed).uniform(-1, 1, n)
def lp(x, k):   # one-pole lowpass
    y = np.zeros_like(x); a = k; s = 0.0
    for i in range(len(x)): s += a * (x[i] - s); y[i] = s
    return y
def sweep(f0, f1, dur, kind='sq', duty=0.5, vol=0.5, curve=1.0):
    n = int(dur * SR); t = np.linspace(0, 1, n) ** curve; f = f0 + (f1 - f0) * t
    ph = np.cumsum(f) / SR; return wave_of(kind, ph, duty) * env(n, 0.002, dur * 0.4) * vol
def tone(f, dur, kind='sq', duty=0.5, vol=0.5, a=0.004, r=0.04):
    n = int(dur * SR); ph = np.arange(n) * f / SR; return wave_of(kind, ph, duty) * env(n, a, r) * vol
def decay_noise(dur, vol=0.5, k=0.5, seed=1, power=2.0):
    n = int(dur * SR); return lp(noise(n, seed), k) * (1 - np.linspace(0, 1, n)) ** power * vol
def mix(*parts):
    n = max(len(p) for p in parts); out = np.zeros(n)
    for p in parts: out[:len(p)] += p
    return out
def seq(*parts):
    return np.concatenate(parts)
def save_wav(path, x, peak=0.85):
    x = x / max(1e-6, np.abs(x).max()) * peak
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())

SFX = {
 'shoot':        lambda: mix(sweep(1100, 260, 0.11, 'sq', 0.25, 0.6), decay_noise(0.05, 0.15, 0.7)),
 'jump':         lambda: sweep(260, 640, 0.15, 'sq', 0.5, 0.5, 0.7),
 'slide':        lambda: decay_noise(0.28, 0.5, 0.18, 3, 1.2),
 'hurt':         lambda: mix(sweep(520, 90, 0.32, 'sq', 0.5, 0.55), decay_noise(0.25, 0.35, 0.5, 4)),
 'enemy_shoot':  lambda: mix(sweep(620, 140, 0.16, 'saw', 0.5, 0.45), decay_noise(0.07, 0.2, 0.6, 5)),
 'enemy_hit':    lambda: mix(decay_noise(0.07, 0.5, 0.6, 6), tone(220, 0.07, 'sq', 0.5, 0.35)),
 'enemy_die':    lambda: mix(decay_noise(0.45, 0.7, 0.3, 7, 1.5), sweep(420, 60, 0.4, 'sq', 0.5, 0.4)),
 'shield_block': lambda: mix(tone(1800, 0.16, 'sin', 0.5, 0.5, 0.001, 0.14), tone(2650, 0.12, 'sin', 0.5, 0.3, 0.001, 0.1), decay_noise(0.02, 0.4, 0.9, 8)),
 'shield_break': lambda: mix(decay_noise(0.5, 0.6, 0.45, 9, 1.4), sweep(2200, 300, 0.45, 'sq', 0.25, 0.3), sweep(1500, 200, 0.4, 'sin', 0.5, 0.3)),
 'spot':         lambda: seq(tone(740, 0.07, 'sq', 0.5, 0.5), tone(990, 0.12, 'sq', 0.5, 0.5)),
 'pickup':       lambda: seq(tone(660, 0.06, 'sq', 0.25, 0.45), tone(880, 0.06, 'sq', 0.25, 0.45), tone(1320, 0.14, 'sq', 0.25, 0.45)),
 'explode':      lambda: mix(decay_noise(0.7, 0.8, 0.25, 10, 1.6), sweep(200, 40, 0.5, 'tri', 0.5, 0.6)),
 'bike_hit':     lambda: mix(decay_noise(0.18, 0.6, 0.5, 11, 1.5), tone(150, 0.14, 'tri', 0.5, 0.5)),
 'menu_move':    lambda: tone(1000, 0.035, 'sq', 0.5, 0.35, 0.001, 0.02),
 'menu_select':  lambda: seq(tone(800, 0.05, 'sq', 0.25, 0.4), tone(1200, 0.09, 'sq', 0.25, 0.4)),
 'blip':         lambda: tone(520, 0.018, 'sq', 0.5, 0.22, 0.001, 0.01),
 'tip_open':     lambda: seq(tone(523, 0.07, 'sq', 0.25, 0.4), tone(784, 0.12, 'sq', 0.25, 0.4)),
 'clear':        lambda: seq(*[tone(f, 0.13, 'sq', 0.25, 0.45) for f in (523, 659, 784, 1047)], tone(1047, 0.18, 'sq', 0.25, 0.45), tone(784, 0.1, 'sq', 0.25, 0.45), tone(1047, 0.55, 'sq', 0.25, 0.5, 0.004, 0.4)),
 'down':         lambda: seq(*[tone(f, 0.2, 'tri', 0.5, 0.6, 0.004, 0.1) for f in (392, 349, 311, 262)], tone(196, 0.7, 'tri', 0.5, 0.6, 0.004, 0.5)),
}

def hum(base, harm, hiss_lo, hiss_hi, wob, dur=2.0, seed=3):
    n = int(dur * SR); t = np.arange(n) / SR; rs = np.random.RandomState(seed); x = np.zeros(n)
    for k, a in harm: x += a * wave_of('saw', t * base * k)
    for f in rs.randint(hiss_lo, hiss_hi, 40): x += 0.025 * np.sin(2 * np.pi * f * t + rs.uniform(0, 6.28))
    return x * (1 + 0.18 * np.sin(2 * np.pi * wob * t))
SFX['bike_engine'] = lambda: lp(hum(96, [(1, 0.5), (2, 0.25), (3, 0.12)], 400, 1800, 7), 0.22)
SFX['ship_engine'] = lambda: lp(hum(48, [(1, 0.6), (2, 0.3), (3, 0.15)], 60, 500, 3), 0.12)

# ---------------- music ----------------
def drum_kick(): n = int(0.14 * SR); f = 150 * np.exp(-np.linspace(0, 1, n) * 3.2) + 40; return np.sin(np.cumsum(f) / SR * 2 * np.pi) * np.linspace(1, 0, n) ** 1.5 * 0.9
def drum_snare(): return mix(decay_noise(0.13, 0.55, 0.8, 12, 1.4), tone(190, 0.08, 'tri', 0.5, 0.3))
def drum_hat(o=False): return decay_noise(0.14 if o else 0.04, 0.22, 0.95, 13, 1.0) * 1.0
SCALES = {'min': [0, 2, 3, 5, 7, 8, 10], 'dor': [0, 2, 3, 5, 7, 9, 10], 'phr': [0, 1, 3, 5, 7, 8, 10]}
def scale_note(root, mode, deg): o, d = divmod(deg, 7); return root + 12 * o + SCALES[mode][d]
def track(name, bpm, root, mode, prog, bass_style, lead_oct, drums, arp, lead_density, seed, bars_each=1, lead_kind='sq', lead_vol=0.30, bar_count=16):
    rng = random.Random(seed); step = 60.0 / bpm / 4.0; sps = int(step * SR)
    bars = bar_count; N = bars * 16 * sps; buf = np.zeros(N + 4 * SR)
    def put(x, at): buf[at:at + len(x)] += x[:len(buf) - at]
    chords = [prog[(b // bars_each) % len(prog)] for b in range(bars)]   # degree of chord root per bar
    # lead motif generation: 4-bar phrase, repeated with variation
    motif = []
    for b in range(4):
        notes = []; s = 0
        while s < 16:
            ln = rng.choice([2, 2, 4, 4, 6, 8]) if lead_density < 0.5 else rng.choice([1, 2, 2, 2, 4])
            if rng.random() < (1 - lead_density) * 0.5: notes.append((s, ln, None))
            else: notes.append((s, ln, rng.choice([0, 2, 4, 1, 3, 5, 4, 2])))
            s += ln
        motif.append(notes)
    for b in range(bars):
        cd = chords[b]; base = b * 16 * sps
        tones = [cd, cd + 2, cd + 4]
        # bass
        bnote = scale_note(root - 24, mode, cd)
        if bass_style == 'drive':
            for i in range(0, 16, 2): put(tone(midi(bnote + (12 if i % 8 == 6 else 0)), step * 1.8, 'tri', 0.5, 0.55, 0.002, 0.03), base + i * sps)
        elif bass_style == 'gallop':
            for i in (0, 3, 4, 7, 8, 11, 12, 15): put(tone(midi(bnote + (12 if i in (7, 15) else 0)), step * 1.6, 'tri', 0.5, 0.55, 0.002, 0.03), base + i * sps)
        elif bass_style == 'walk':
            for k, i in enumerate((0, 4, 8, 12)): put(tone(midi(bnote + (0, 0, 7, 5)[k]), step * 3.6, 'tri', 0.5, 0.55, 0.003, 0.08), base + i * sps)
        else:   # long
            put(tone(midi(bnote), step * 15.5, 'tri', 0.5, 0.6, 0.01, 0.2), base)
        # arp
        if arp:
            for i in range(16):
                if arp == 2 and i % 2: continue
                d = tones[[0, 1, 2, 1][(i // (1 if arp == 1 else 2)) % 4]] + 7
                put(tone(midi(scale_note(root, mode, d)), step * 0.9, 'sq', 0.125, 0.16, 0.002, 0.03), base + i * sps)
        # lead
        if lead_density > 0:
            for (s, ln, deg) in motif[b % 4]:
                if deg is None: continue
                dg = deg + cd + (7 if b % 8 >= 4 and rng.random() < 0.4 else 0)
                f = midi(scale_note(root + 12 * lead_oct, mode, dg)); n = int(ln * step * SR * 0.97)
                tt = np.arange(n) / SR; vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * tt) * np.clip((tt - 0.12) * 8, 0, 1)
                ph = np.cumsum(f * vib) / SR
                put(wave_of(lead_kind, ph, 0.25 if lead_kind == 'sq' else 0.5) * env(n, 0.004, 0.06) * lead_vol, base + s * sps)
        # drums
        for i in range(16):
            at = base + i * sps
            if drums == 'four':
                if i % 4 == 0: put(drum_kick(), at)
                if i % 8 == 4: put(drum_snare(), at)
                if i % 2 == 0: put(drum_hat(i % 8 == 6), at)
            elif drums == 'half':
                if i == 0 or (i == 10 and b % 2): put(drum_kick(), at)
                if i == 8: put(drum_snare(), at)
                if i % 4 == 2: put(drum_hat(), at)
            elif drums == 'sparse':
                if i == 0: put(drum_kick() * 0.8, at)
                if i == 12 and b % 2: put(drum_snare() * 0.5, at)
                if i % 8 == 4: put(drum_hat(), at)
            elif drums == 'drive':
                if i % 4 == 0 or (i % 8 == 6): put(drum_kick(), at)
                if i % 8 == 4: put(drum_snare(), at)
                put(drum_hat(), at) if i % 2 == 0 else None
    out = buf[:N].copy(); out[:len(buf) - N] += buf[N:N + len(buf) - N][:len(out)] if len(buf) - N <= N else 0   # wrap tails so it loops cleanly
    return out
TRACKS = {
 'title':   dict(bpm=84,  root=57, mode='min', prog=[0, 5, 3, 4],        bass_style='long',  lead_oct=1, drums='sparse', arp=2, lead_density=0.35, seed=11, bars_each=2, lead_kind='tri', lead_vol=0.4),
 'desert':  dict(bpm=96,  root=50, mode='dor', prog=[0, 0, 3, 4, 0, 5, 3, 4], bass_style='walk', lead_oct=1, drums='half', arp=2, lead_density=0.4, seed=21, lead_kind='tri', lead_vol=0.38),
 'highway': dict(bpm=124, root=52, mode='min', prog=[0, 5, 6, 4],       bass_style='drive', lead_oct=1, drums='four', arp=1, lead_density=0.7, seed=31, lead_vol=0.26),
 'town':    dict(bpm=92,  root=57, mode='phr', prog=[0, 0, 1, 0, 0, 6, 1, 0], bass_style='long', lead_oct=0, drums='sparse', arp=2, lead_density=0.25, seed=41, lead_kind='tri', lead_vol=0.4),
 'bike':    dict(bpm=150, root=54, mode='min', prog=[0, 5, 3, 6],       bass_style='gallop', lead_oct=1, drums='drive', arp=1, lead_density=0.8, seed=51, lead_vol=0.26),
 'space':   dict(bpm=128, root=50, mode='min', prog=[0, 3, 5, 4, 0, 3, 6, 4], bass_style='drive', lead_oct=1, drums='four', arp=1, lead_density=0.6, seed=61, lead_vol=0.28),
}
if __name__ == '__main__':
    os.makedirs('assets/sfx', exist_ok=True); os.makedirs('assets/music', exist_ok=True)
    for k, f in SFX.items(): save_wav('assets/sfx/%s.wav' % k, f()); print('sfx', k)
    for k, spec in TRACKS.items():
        x = track(k, **spec); tmp = '/tmp/_%s.wav' % k; save_wav(tmp, x, 0.8)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp, '-c:a', 'libvorbis', '-q:a', '3', 'assets/music/%s.ogg' % k], check=True)
        print('music', k, round(len(x) / SR, 1), 's')
