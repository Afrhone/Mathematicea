from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
assert (root/'web/index.html').exists()
data=json.loads((root/'web/assets/glyphs.json').read_text())
assert len(data['glyphs']) >= 60
assert set(data['families']) >= {'root','bridge','form','rhythm','nature','momentum','axiom'}
for g in data['glyphs']:
    assert 'char' in g and 'strokes' in g
print('ok', len(data['glyphs']), 'glyphs')

preset=json.loads((root/'web/assets/presets/functorial-alphabet.json').read_text())
assert preset['slug']=='functorial-alphabet'
assert len(preset['alphabetMap']) >= len(data['glyphs'])
assert 'Graphème' in preset['category']['objects']
assert (root/'web/js/flowforms-presets.js').exists()
print('preset', preset['name'], len(preset['alphabetMap']), 'mappings')
