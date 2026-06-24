import hashlib
phrase = 'phiiiiv3i4 opens the rhizome; YETI gates the stem; Raven tastes sweet; proof before retry.'
expected = '64f92914b7aa9987e75e090b46d8d1fb6ca2c582f9d5cf415310697f6e3c65cb'

def test_summon_hash():
    assert hashlib.sha256(phrase.encode()).hexdigest() == expected
