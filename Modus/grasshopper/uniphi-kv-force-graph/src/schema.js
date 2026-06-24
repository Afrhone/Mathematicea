export const DATASET_SCHEMA = {
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://uniphi.local/schemas/kv-cache-dataset.json",
  "title": "Uniphi KV Cache Dataset (Conceptual)",
  "type": "object",
  "required": ["meta","tokens"],
  "properties": {
    "meta": {
      "type": "object",
      "required": ["model"],
      "properties": {
        "model": {
          "type": "object",
          "required": ["name","n_layers","n_heads","d_head","dtype_bytes"],
          "properties": {
            "name": {"type":"string"},
            "n_layers": {"type":"integer","minimum":1},
            "n_heads": {"type":"integer","minimum":1},
            "d_head": {"type":"integer","minimum":1},
            "dtype_bytes": {"type":"integer","enum":[1,2,4,8]},
            "kv": {
              "type":"object",
              "properties": {
                "stores": {"type":"array","items":{"type":"string","enum":["K","V"]}},
                "bytes_per_entry": {"type":"integer","enum":[1,2,4,8]}
              }
            }
          }
        },
        "graph": { "type":"object", "properties": { "topk": {"type":"integer","minimum":1} } }
      }
    },
    "tokens": {
      "type":"array",
      "items":{
        "type":"object",
        "required":["id","pos","text"],
        "properties":{
          "id":{"type":"string"},
          "pos":{"type":"integer","minimum":0},
          "text":{"type":"string"}
        }
      }
    },
    "kv_stats": {
      "description":"Optional sparse stats proxy. Prefer norms or PCA projections over raw tensors.",
      "type":"object",
      "properties":{
        "layers":{
          "type":"array",
          "items":{
            "type":"object",
            "required":["index","heads"],
            "properties":{
              "index":{"type":"integer","minimum":0},
              "heads":{
                "type":"array",
                "items":{
                  "type":"object",
                  "required":["index","k_norm","v_norm"],
                  "properties":{
                    "index":{"type":"integer","minimum":0},
                    "k_norm":{"type":"array","items":{"type":"number"}},
                    "v_norm":{"type":"array","items":{"type":"number"}}
                  }
                }
              }
            }
          }
        }
      }
    },
    "attn_links": {
      "description":"Optional sparse attention links per layer/head/topk.",
      "type":"object",
      "properties":{
        "layers":{
          "type":"array",
          "items":{
            "type":"object",
            "required":["index","heads"],
            "properties":{
              "index":{"type":"integer","minimum":0},
              "heads":{
                "type":"array",
                "items":{
                  "type":"object",
                  "required":["index","topk","links"],
                  "properties":{
                    "index":{"type":"integer","minimum":0},
                    "topk":{"type":"integer","minimum":1},
                    "links":{
                      "type":"array",
                      "items":{
                        "type":"object",
                        "required":["source","target","weight"],
                        "properties":{
                          "source":{"type":"string"},
                          "target":{"type":"string"},
                          "weight":{"type":"number","minimum":0,"maximum":1}
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
};
