  $ merl-an benchmark -s 1 -p bench.ml --data=test-data

  $ jq . test-data/bench.json
  {
    "name": "Merlin benchmark",
    "results": [
      {
        "name": "result",
        "metrics": [
          {
            "name": "/Users/rafal/Projects/Tarides/merl-an/_build/default/test/bench.t/bench.ml",
            "value": 0,
            "units": "todo",
            "description": "errors",
            "trend": null
          },
          {
            "name": "/Users/rafal/Projects/Tarides/merl-an/_build/default/test/bench.t/bench.ml",
            "value": 0,
            "units": "todo",
            "description": "type-enclosing",
            "trend": null
          },
          {
            "name": "/Users/rafal/Projects/Tarides/merl-an/_build/default/test/bench.t/bench.ml",
            "value": 0,
            "units": "todo",
            "description": "case-analysis",
            "trend": null
          }
        ]
      }
    ]
  }
