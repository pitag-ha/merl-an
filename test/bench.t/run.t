  $ merl-an benchmark -s 2 -p bench.ml,bench1.ml --data=test-data

  $ jq '.results |= map( .metrics |= map(.value |= map(0)))' test-data/bench.json
  {
    "results": [
      {
        "name": "buffer-typed",
        "metrics": [
          {
            "name": "case-analysis",
            "value": [
              0,
              0,
              0,
              0
            ],
            "units": "ms"
          },
          {
            "name": "complete-prefix",
            "value": [
              0,
              0,
              0
            ],
            "units": "ms"
          },
          {
            "name": "errors",
            "value": [
              0,
              0
            ],
            "units": "ms"
          },
          {
            "name": "expand-prefix",
            "value": [
              0,
              0,
              0
            ],
            "units": "ms"
          },
          {
            "name": "locate",
            "value": [
              0,
              0,
              0
            ],
            "units": "ms"
          },
          {
            "name": "occurrences",
            "value": [
              0,
              0,
              0
            ],
            "units": "ms"
          },
          {
            "name": "type-enclosing",
            "value": [
              0,
              0,
              0,
              0
            ],
            "units": "ms"
          }
        ]
      }
    ]
  }

  $ cat test-data/bench.json |
  > jq '.results |= map( .metrics |= map(.value |= map(0)))' |
  > cb-check
  Correctly parsed some benchmarks:
  {
    "name": null,
    "results": [
      {
        "name": "buffer-typed",
        "metrics": [
          {
            "name": "case-analysis",
            "description": "",
            "value": [ 0.0, 0.0, 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "complete-prefix",
            "description": "",
            "value": [ 0.0, 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "errors",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "expand-prefix",
            "description": "",
            "value": [ 0.0, 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "locate",
            "description": "",
            "value": [ 0.0, 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "occurrences",
            "description": "",
            "value": [ 0.0, 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "type-enclosing",
            "description": "",
            "value": [ 0.0, 0.0, 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          }
        ]
      }
    ]
  }
