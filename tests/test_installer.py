"""Exercise installer branches without installing packages or using the network."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
DEFINITIONS = (REPO / 'scripts/install-recon-tools.sh').read_text().split('# ─── main')[0]


class InstallerTests(unittest.TestCase):
    def run_shell(self, body):
        with tempfile.TemporaryDirectory() as home:
            result = subprocess.run(
                ['bash', '-c', DEFINITIONS + '\n' + body],
                env=dict(os.environ, HOME=home), text=True, capture_output=True,
            )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_apt_packages_and_cpp_requirement(self):
        output = self.run_shell('''
ASSUME_YES=1
installed=0
have() {
  case "$1" in
    apt-get|cc|gcc) return 0 ;;
    pacman|dnf|brew) return 1 ;;
    *) (( installed )) ;;
  esac
}
run_as_root() {
  printf 'CALL'; printf ' <%s>' "$@"; printf '\\n'
  [[ "$2" != install ]] || installed=1
}
install_system_packages
(( ${#FAILED[@]} == 0 ))
''')
        self.assertIn('CALL <apt-get> <update>', output)
        self.assertIn('CALL <apt-get> <install> <-y>', output)
        for package in ('golang-go', 'g++', 'pipx', 'zsh', 'ripgrep'):
            self.assertIn('<' + package + '>', output)

    def test_check_only_never_installs(self):
        output = self.run_shell('''
CHECK_ONLY=1
have() { return 1; }
run_as_root() { echo UNEXPECTED_INSTALL; return 99; }
install_system_packages
install_go_tools
install_waymore
install_urldedupe
''')
        self.assertNotIn('UNEXPECTED_INSTALL', output)
        self.assertIn('zsh', output)

    def test_missing_pipx_fails_without_pip(self):
        self.run_shell('''
have() { return 1; }
python3() { echo UNEXPECTED_PIP; exit 99; }
install_waymore
[[ ${#FAILED[@]} == 1 && ${FAILED[0]} == waymore ]]
''')

    def test_privilege_dispatch(self):
        self.run_shell('''
sudo() { printf 'sudo '; "$@"; }
have() { [[ "$1" == sudo ]]; }
result=$(run_as_root printf apt)
if (( EUID == 0 )); then
  [[ "$result" == apt ]]
else
  [[ "$result" == 'sudo apt' ]]
fi
''')


if __name__ == '__main__':
    unittest.main()
