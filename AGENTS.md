# Last crusuade
Is inspired by the board game pixel tactics

## Run the game
`timeout 10 docker run --volume .:/var/godot prijindal/godot:4.6.2-stable-mono godot --headless --path=/var/godot`

## Run the tests
Test runner scene is `res://tests/runner.tscn` (see `tests/runner.gd`); it runs the suites under `tests/suites/` and exits with code `0` if all tests pass, `1` otherwise.

```
docker run --volume .:/var/godot --name godot-dev -d prijindal/godot:4.6.2-stable-mono sleep infinity
timeout 120 docker exec -w /var/godot godot-dev godot --headless --path=/var/godot res://tests/runner.tscn
docker stop godot-dev
docker rm godot-dev
```
