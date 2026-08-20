#!/bin/zsh --no-rcs

setopt ERR_EXIT
setopt NO_UNSET
setopt PIPE_FAIL

repoRoot="${0:A:h:h}"
scriptPath="${repoRoot}/SYM-Lite.zsh"
temporaryDirectory="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/sym-lite-parser-tests.XXXXXX")"
validFixture="${temporaryDirectory}/Installomator-valid.zsh"
incompleteFixture="${temporaryDirectory}/Installomator-incomplete.zsh"

function cleanup() {
    /bin/rm -rf -- "${temporaryDirectory}"
}
trap cleanup EXIT

function fail() {
    print -u2 -r -- "FAIL: $1"
    exit 1
}

function extractFunction() {
    local functionName="$1"

    /usr/bin/awk -v functionName="${functionName}" '
        $0 == "function " functionName "() {" {
            capture = 1
        }

        capture {
            print
        }

        capture && /^}$/ {
            exit
        }
    ' "${scriptPath}"
}

function loadProductionFunction() {
    local functionName="$1"
    local functionSource=""

    functionSource="$(extractFunction "${functionName}")"
    [[ -n "${functionSource}" ]] || fail "Unable to extract ${functionName} from SYM-Lite.zsh"
    eval "${functionSource}"
}

function assertOutputContains() {
    local output="$1"
    local expected="$2"

    print -r -- "${output}" | /usr/bin/grep -Fqx -- "${expected}" \
        || fail "Expected parsed label '${expected}'"
}

function assertOutputExcludes() {
    local output="$1"
    local unexpected="$2"

    if print -r -- "${output}" | /usr/bin/grep -Fqx -- "${unexpected}"; then
        fail "Unexpected parsed label '${unexpected}'"
    fi
}

loadProductionFunction "parseInstallomatorItem"
loadProductionFunction "getAvailableInstallomatorLabels"
loadProductionFunction "normalizeInstallomatorLabels"

function preFlight() { :; }
function warning() { :; }
function errorOut() { :; }

/bin/cat > "${validFixture}" <<'FIXTURE'
case $label in
    singlelabel|singlealias)
        ;;
    multilinefirst|\
    multilinesecond|\
    multilinethird)
        ;;
    parentlabel)
        case "${nestedValue}" in
            nestedalias)
                ;;
        esac
        ;;
    longversion)
        ;;
    valuesfromarguments)
        ;;
    *)
        ;;
esac
FIXTURE
/bin/chmod +x "${validFixture}"

organizationInstallomatorFile="${validFixture}"
parsedLabels="$(getAvailableInstallomatorLabels)" \
    || fail "Valid fixture returned a parse failure"

assertOutputContains "${parsedLabels}" "singlelabel"
assertOutputContains "${parsedLabels}" "singlealias"
assertOutputContains "${parsedLabels}" "multilinefirst"
assertOutputContains "${parsedLabels}" "multilinesecond"
assertOutputContains "${parsedLabels}" "multilinethird"
assertOutputContains "${parsedLabels}" "parentlabel"
assertOutputExcludes "${parsedLabels}" "nestedalias"
assertOutputExcludes "${parsedLabels}" "longversion"
assertOutputExcludes "${parsedLabels}" "valuesfromarguments"
assertOutputExcludes "${parsedLabels}" "*"

configuredInstallomatorLabels=(
    "multilinefirst | Multiline Label | /Applications/Multiline.app | https://example.invalid/icon.png"
)
installomatorLabels=("${configuredInstallomatorLabels[@]}")
normalizeInstallomatorLabels

[[ ${#installomatorLabels[@]} -eq 1 ]] \
    || fail "Normalization removed a configured multiline alias"
[[ "${installomatorLabels[1]}" == "${configuredInstallomatorLabels[1]}" ]] \
    || fail "Normalization changed the configured multiline alias"

/bin/cat > "${incompleteFixture}" <<'FIXTURE'
case $label in
    incompletealias|\
FIXTURE
/bin/chmod +x "${incompleteFixture}"

organizationInstallomatorFile="${incompleteFixture}"
if getAvailableInstallomatorLabels >/dev/null 2>&1; then
    fail "Incomplete continuation arm did not return a parse failure"
fi

print -r -- "PASS: Installomator label parser regression tests"