test :; pytest tests/
build :; rm -rf dist && python -m build
compile :; nile compile --directory src