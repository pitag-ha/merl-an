  $ merl-an benchmark -s 1 -p bench.ml --data=test-data

  $ jq '.results |= map (.metrics |= map ( .name="x"))' test-data/bench.json
  {
    "name": "Merlin benchmark",
    "results": [
      {
        "name": "result",
        "metrics": [
          {
            "name": "x",
            "value": 0,
            "units": "todo",
            "description": "errors",
            "trend": null
          },
          {
            "name": "x",
            "value": 0,
            "units": "todo",
            "description": "type-enclosing",
            "trend": null
          },
          {
            "name": "x",
            "value": 0,
            "units": "todo",
            "description": "case-analysis",
            "trend": null
          }
        ]
      }
    ]
  }
