  $ merl-an benchmark -s 2 -p bench.ml,bench1.ml --data=test-data

  $ jq '.results |= map( .metrics |= map(.value |= map(0)))' test-data/bench.json
  {
    "name": "Merlin benchmark",
    "results": [
      {
        "name": "bench.ml",
        "metrics": [
          {
            "name": "case-analysis",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "complete-prefix",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "errors",
            "value": [
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "expand-prefix",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "locate",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "occurrences",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "type-enclosing",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          }
        ]
      },
      {
        "name": "bench1.ml",
        "metrics": [
          {
            "name": "case-analysis",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "complete-prefix",
            "value": [
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "errors",
            "value": [
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "expand-prefix",
            "value": [
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "locate",
            "value": [
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "occurrences",
            "value": [
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
          },
          {
            "name": "type-enclosing",
            "value": [
              0,
              0
            ],
            "units": "ms",
            "description": "",
            "trend": null
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
    "name": "Merlin benchmark",
    "results": [
      {
        "name": "bench.ml",
        "metrics": [
          {
            "name": "case-analysis",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "complete-prefix",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "errors",
            "description": "",
            "value": [ 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "expand-prefix",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "locate",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "occurrences",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "type-enclosing",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          }
        ]
      },
      {
        "name": "bench1.ml",
        "metrics": [
          {
            "name": "case-analysis",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "complete-prefix",
            "description": "",
            "value": [ 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "errors",
            "description": "",
            "value": [ 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "expand-prefix",
            "description": "",
            "value": [ 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "locate",
            "description": "",
            "value": [ 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "occurrences",
            "description": "",
            "value": [ 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          },
          {
            "name": "type-enclosing",
            "description": "",
            "value": [ 0.0, 0.0 ],
            "units": "ms",
            "trend": "",
            "lines": []
          }
        ]
      }
    ]
  }

  $ cat test-data/commands.json |
  > jq -c '.cmd |= sub("-filename.*"; "-filename")'
  {"sample_id":24,"cmd":"ocamlmerlin server errors -filename","merlin_id":0}
  {"sample_id":23,"cmd":" ocamlmerlin server locate -look-for ml -position '5:14' -index 0 -filename","merlin_id":0}
  {"sample_id":22,"cmd":" ocamlmerlin server locate -look-for ml -position '3:14' -index 0 -filename","merlin_id":0}
  {"sample_id":21,"cmd":"ocamlmerlin server expand-prefix -prefix List -position '5:14' -filename","merlin_id":0}
  {"sample_id":20,"cmd":"ocamlmerlin server expand-prefix -prefix List -position '3:14' -filename","merlin_id":0}
  {"sample_id":19,"cmd":"ocamlmerlin server complete-prefix -prefix List -position '5:14' -filename","merlin_id":0}
  {"sample_id":18,"cmd":"ocamlmerlin server complete-prefix -prefix List -position '3:14' -filename","merlin_id":0}
  {"sample_id":17,"cmd":"ocamlmerlin server occurrences -identifier-at '5:14' -filename","merlin_id":0}
  {"sample_id":16,"cmd":"ocamlmerlin server occurrences -identifier-at '3:14' -filename","merlin_id":0}
  {"sample_id":15,"cmd":"ocamlmerlin server type-enclosing -position '3:14' -filename","merlin_id":0}
  {"sample_id":14,"cmd":"ocamlmerlin server type-enclosing -position '1:8' -filename","merlin_id":0}
  {"sample_id":13,"cmd":"ocamlmerlin server case-analysis -start '3:8' -end '3:14' -filename","merlin_id":0}
  {"sample_id":12,"cmd":"ocamlmerlin server case-analysis -start '1:8' -end '1:8' -filename","merlin_id":0}
  {"sample_id":12,"cmd":"ocamlmerlin server errors -filename","merlin_id":0}
  {"sample_id":10,"cmd":" ocamlmerlin server locate -look-for ml -position '3:16' -index 0 -filename","merlin_id":0}
  {"sample_id":8,"cmd":"ocamlmerlin server expand-prefix -prefix List -position '3:16' -filename","merlin_id":0}
  {"sample_id":6,"cmd":"ocamlmerlin server complete-prefix -prefix List -position '3:16' -filename","merlin_id":0}
  {"sample_id":4,"cmd":"ocamlmerlin server occurrences -identifier-at '3:16' -filename","merlin_id":0}
  {"sample_id":3,"cmd":"ocamlmerlin server type-enclosing -position '3:16' -filename","merlin_id":0}
  {"sample_id":2,"cmd":"ocamlmerlin server type-enclosing -position '1:8' -filename","merlin_id":0}
  {"sample_id":1,"cmd":"ocamlmerlin server case-analysis -start '3:6' -end '3:16' -filename","merlin_id":0}
  {"sample_id":0,"cmd":"ocamlmerlin server case-analysis -start '3:10' -end '3:16' -filename","merlin_id":0}
  $ cat test-data/query_responses.json |
  > jq -c '.responses |= map (.timing |=
  > (.clock |= 0
  > | .cpu |= 0
  > | .query |= 0
  > | .reader |= 0
  > | .typer |= 0
  > | .error |= 0)
  > )'
  {"sample_id":24,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":23,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":22,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":21,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":20,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":19,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":18,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":17,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":16,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":15,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":14,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":13,"responses":[{"class":"error","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":12,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":12,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":10,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":8,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":6,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":4,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":3,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":2,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":1,"responses":[{"class":"error","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":0,"responses":[{"class":"error","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
