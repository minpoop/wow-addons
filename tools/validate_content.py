"""Validate data-only JSON through the addon's Lua schemas; never execute imports."""
import argparse
import json
from pathlib import Path
from lupa.lua51 import LuaRuntime


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'duplicate JSON key: {key}')
        result[key] = value
    return result


def read_json(path):
    if path.stat().st_size > 2_000_000:
        raise ValueError('content exceeds 2 MB validation limit')
    return json.loads(path.read_text(), object_pairs_hook=unique_object,
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(f'nonfinite value: {value}')))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('kind', choices=['guide', 'profession', 'route'])
    parser.add_argument('file', type=Path)
    parser.add_argument('--production', action='store_true', help='Require live-verified source declarations')
    parser.add_argument('--known-quests', type=Path, help='Verified JSON array of existing quest IDs; guides only')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    try:
        lua = LuaRuntime(unpack_returned_tuples=True)
        for filename in ['Core/Namespace.lua', 'Core/Validation.lua', 'Core/SavedVariables.lua',
                         'Questing/StepValidator.lua', 'Professions/MaterialCalculator.lua',
                         'Professions/RecipeDatabase.lua', 'Navigation/GatheringRoutes.lua']:
            lua.execute((root / 'ForeverXP' / filename).read_text())

        def convert(value):
            if isinstance(value, dict):
                return lua.table_from({key: convert(child) for key, child in value.items()})
            if isinstance(value, list):
                return lua.table_from([convert(child) for child in value])
            if value is None:
                raise ValueError('JSON null is unsupported; omit optional fields')
            return value

        data = convert(read_json(args.file))
        module, method = {'guide': ('StepValidator', 'Guide'),
                          'profession': ('RecipeDatabase', 'Validate'),
                          'route': ('GatheringRoutes', 'Validate')}[args.kind]
        validate = lua.eval(f'function(data, production) local ok, err = ForeverXP.modules.{module}:{method}(data, production); return ok, err end')
        ok, errors = validate(data, args.production)
        if not ok:
            message = '; '.join(str(value) for value in errors.values()) if lua.eval('type')(errors) == 'table' else str(errors)
            raise ValueError(message)
        if args.known_quests:
            if args.kind != 'guide':
                raise ValueError('--known-quests applies only to guides')
            known = read_json(args.known_quests)
            if not isinstance(known, list) or any(type(item) is not int or item <= 0 for item in known):
                raise ValueError('known quest IDs must be positive integers in an array')
            check = lua.eval('function(guide, known) return ForeverXP.modules.StepValidator:KnownQuests(guide, known) end')
            exists, missing = check(data, lua.table_from({item: True for item in known}))
            if not exists:
                raise ValueError('quest IDs missing from supplied catalog: ' + ', '.join(str(int(key)) for key in sorted(missing.keys())))
    except (OSError, ValueError, RecursionError) as error:
        parser.exit(1, f'INVALID: {error}\n')
    print('VALID structure' + (' and source declaration' if args.production else '') + '; server correctness requires live verification')


if __name__ == '__main__':
    main()
