test :; pytest tests/
build :; rm -r dist && python -m build
compile :; nile compile --directory src