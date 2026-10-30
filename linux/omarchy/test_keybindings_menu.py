from pathlib import Path
import os
import subprocess
import tempfile
import unittest

MENU = Path(__file__).resolve().parents[2] / 'common' / 'bin' / 'keybindings-menu'


class KeybindingsMenuTest(unittest.TestCase):
    def test_linux_only_map_renders_available_bindings(self):
        with tempfile.TemporaryDirectory() as home:
            doc = Path(home) / 'dev-env' / 'KEYBINDINGS.md'
            doc.parent.mkdir()
            doc.write_text('''# Keybindings

## Windows

| Key | Action | Linux |
|---|---|---|
| Super+W | close window | Omarchy |
| Super+H | focus mode | focus-mode |
| Super+Z | unavailable | . |

## Apps

| App | Description | Linux |
|---|---|---|
| Editor | ordinary app inventory | installed |
''')
            result = subprocess.run(
                ['bash', str(MENU), '--print'],
                env={**os.environ, 'HOME': home}, capture_output=True, text=True,
                check=True,
            )
            self.assertIn('SUPER+W', result.stdout)
            self.assertIn('close window', result.stdout)
            self.assertIn('SUPER+H', result.stdout)
            self.assertNotIn('SUPER+Z', result.stdout)
            self.assertNotIn('ordinary app inventory', result.stdout)


if __name__ == '__main__':
    unittest.main()
