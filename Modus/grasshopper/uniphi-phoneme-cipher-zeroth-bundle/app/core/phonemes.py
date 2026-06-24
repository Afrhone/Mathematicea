from __future__ import annotations
import re

TOKENS = [
    "i","e","ɛ","a","ɑ","o","ɔ","u","y","ø","œ","ə",
    "ɛ̃","ɑ̃","ɔ̃","œ̃",
    "j","w","ɥ",
    "p","b","t","d","k","g","f","v","s","z","ʃ","ʒ",
    "m","n","ɲ","ŋ","l","ʁ"
]
TOKEN_SET = set(TOKENS)

_PATTERNS = [
    (r"eaux", "o"),
    (r"eau", "o"),
    (r"au", "o"),
    (r"ai", "ɛ"),
    (r"ei", "ɛ"),
    (r"é", "e"),
    (r"è|ê", "ɛ"),
    (r"à", "a"),
    (r"â", "ɑ"),
    (r"ô", "o"),
    (r"î", "i"),
    (r"û", "y"),
    (r"ù", "y"),
    (r"ç", "s"),
    (r"ph", "f"),
    (r"th", "t"),
    (r"ch", "ʃ"),
    (r"gn", "ɲ"),
    (r"qu", "k"),
    (r"gu(?=[eiéèê])", "g"),
    (r"(ain|ein|in|im|yn|ym)", "ɛ̃"),
    (r"(an|am|en|em)", "ɑ̃"),
    (r"(on|om)", "ɔ̃"),
    (r"(un|um)", "œ̃"),
    (r"oi", "w a"),
    (r"ou", "u"),
    (r"ui", "ɥ i"),
    (r"ill(?=[aeiouy])", "j"),
    (r"ille", "j"),
]

_SINGLE = {
    "a":"a","b":"b","c":"k","d":"d","e":"ə","f":"f","g":"g","h":"",
    "i":"i","j":"ʒ","k":"k","l":"l","m":"m","n":"n","o":"o","p":"p",
    "q":"k","r":"ʁ","s":"s","t":"t","u":"y","v":"v","w":"w","x":"k s",
    "y":"j","z":"z","œ":"œ","æ":"e"
}

_WORD_FINAL_SILENT = re.compile(r"(e|es|ent|s|t|d|x)$")

def normalize(text: str) -> str:
    t = text.strip().lower()
    t = re.sub(r"[^a-zàâçéèêëîïôùûüÿœæ\s'-]+", " ", t)
    t = t.replace("’","'")
    t = re.sub(r"\s+", " ", t).strip()
    return t

def word_simplify(word: str) -> str:
    if len(word) > 2:
        word = _WORD_FINAL_SILENT.sub("", word)
    return word

def g2p_lite(text: str) -> list[str]:
    t = normalize(text)
    if not t:
        return []
    toks: list[str] = []
    for raw in t.split(" "):
        if not raw:
            continue
        w = word_simplify(raw)
        i = 0
        while i < len(w):
            matched = False
            for pat, rep in _PATTERNS:
                m = re.match(pat, w[i:])
                if m:
                    piece = rep.strip()
                    if piece:
                        toks.extend(piece.split(" "))
                    i += len(m.group(0))
                    matched = True
                    break
            if matched:
                continue
            ch = w[i]
            rep = _SINGLE.get(ch, "")
            if rep:
                toks.extend(rep.split(" "))
            i += 1
    toks = [x for x in toks if x in TOKEN_SET]
    return toks

VOWELS = {"i","e","ɛ","a","ɑ","o","ɔ","u","y","ø","œ","ə","ɛ̃","ɑ̃","ɔ̃","œ̃"}
NASALS = {"m","n","ɲ","ŋ"}
LIQUIDS = {"l","ʁ"}
OBSTRUENTS = {"p","b","t","d","k","g","f","v","s","z","ʃ","ʒ"}

def class_of(tok: str) -> str:
    if tok in VOWELS: return "R"
    if tok in NASALS or tok in LIQUIDS: return "N"
    if tok in OBSTRUENTS: return "Z"
    return "N"

def feature_vec(tok: str) -> list[float]:
    vowel = 1.0 if tok in VOWELS else 0.0
    nasal = 1.0 if tok in NASALS or tok in {"ɛ̃","ɑ̃","ɔ̃","œ̃"} else 0.0
    obstr = 1.0 if tok in OBSTRUENTS else 0.0
    voiced = 1.0 if tok in {"b","d","g","v","z","ʒ","m","n","ɲ","ŋ","l","ʁ"} else 0.0
    rounded = 1.0 if tok in {"u","y","o","ɔ","ø","œ","œ̃","ɔ̃"} else 0.0
    front = 1.0 if tok in {"i","e","ɛ","y","ø","œ","ɛ̃","œ̃"} else 0.0
    open_ = 1.0 if tok in {"a","ɑ","ɛ","ɔ","ɑ̃"} else 0.0
    fric = 1.0 if tok in {"f","v","s","z","ʃ","ʒ"} else 0.0
    stop = 1.0 if tok in {"p","b","t","d","k","g"} else 0.0
    liquid = 1.0 if tok in {"l","ʁ"} else 0.0
    semi = 1.0 if tok in {"j","w","ɥ"} else 0.0
    return [vowel,nasal,obstr,voiced,rounded,front,open_,fric,stop,liquid,semi]
