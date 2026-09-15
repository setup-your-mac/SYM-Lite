#!/bin/zsh --no-rcs

# Native macOS tests: synthetic fleetd files and mock curl, with real plutil.
# Never source the entrypoint, read a live Desktop token, or contact a server.
setopt ERR_EXIT NO_UNSET PIPE_FAIL TYPESET_SILENT

repoRoot="${0:A:h:h}"
scriptPath="${repoRoot}/SYM-Lite.zsh"
temporaryDirectory="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/sym-lite-fleet-transport.XXXXXX")"
syntheticTokenA="11111111-1111-4111-8111-111111111111"
syntheticTokenB="22222222-2222-4222-8222-222222222222"
fleetOrbitRoot="${temporaryDirectory}/orbit"
launchDaemonFixture="${temporaryDirectory}/orbit.plist"
curlArgumentsFile="${temporaryDirectory}/curl-arguments"
curlConfigFile="${temporaryDirectory}/curl-config"
curlCallsFile="${temporaryDirectory}/curl-calls"
traceFile="${temporaryDirectory}/trace"
testName="setup"
testCount=0

function cleanup() { /bin/rm -rf -- "${temporaryDirectory}"; }
trap cleanup EXIT
function fail() { print -u2 -r -- "FAIL: ${testName}: $1"; exit 1; }
function assertEqual() { [[ "$1" == "$2" ]] || fail "$3"; }

function loadProductionFunction() {
    local functionName="$1"
    local functionSource=""
    local liveLaunchDaemon="/Library/LaunchDaemons/com.fleetdm.orbit.plist"
    local curlBinary="/usr/bin/curl"
    local fixtureReference='"${launchDaemonFixture}"'

    functionSource=$(/usr/bin/awk -v functionName="${functionName}" '
        $0 == "function " functionName "() {" { capture = 1 }
        capture { print }
        capture && /^}$/ { exit }
    ' "${scriptPath}")
    [[ -n "${functionSource}" ]] || fail "Unable to extract ${functionName}"
    # Redirect only the live plist location and HTTP executable. All parsing,
    # request arguments, deadlines, URL validation, and token reads stay real.
    functionSource="${functionSource//${liveLaunchDaemon}/${fixtureReference}}"
    functionSource="${functionSource//${curlBinary}/mockFleetCurl}"
    [[ "${functionSource}" != *"${liveLaunchDaemon}"* && "${functionSource}" != *"${curlBinary}"* ]] \
        || fail "A live dependency remained in the extracted function"
    eval "${functionSource}"
}

function mockFleetCurl() {
    print -r -- "call" >> "${curlCallsFile}"
    printf '%s\n' "$@" > "${curlArgumentsFile}"
    /bin/cat > "${curlConfigFile}"
    printf '%s\n%s' "${mockCurlBody}" "${mockCurlHTTPStatus}"
    return "${mockCurlExitCode}"
}

function resetCase() {
    testName="$1"
    ((testCount += 1))
    : > "${curlCallsFile}"
    : > "${curlArgumentsFile}"
    : > "${curlConfigFile}"
    /bin/rm -f -- "${launchDaemonFixture}" "${fleetOrbitRoot}/fleet_url.txt"
    print -r -- "${syntheticTokenA}" > "${fleetOrbitRoot}/identifier"
    fleetURL="https://fleet.example.invalid"
    fleetDeadline=0
    fleetDeviceBaseURL=""
    fleetResponse=""
    fleetHTTPStatus=""
    mockCurlHTTPStatus=200
    mockCurlBody='{"ok":true}'
    mockCurlExitCode=0
}

function assertCallCount() {
    local expectedCount="$1"
    local actualCount="$(/usr/bin/wc -l < "${curlCallsFile}")"
    [[ "${actualCount}" -eq "${expectedCount}" ]] || fail "Unexpected HTTP call count"
}

/bin/mkdir -p "${fleetOrbitRoot}"
for functionName in fleetJSONValue fleetReadDeviceURL fleetRequest; do
    loadProductionFunction "${functionName}"
done

resetCase "token stays in curl stdin"
fleetRequest GET "/software" || fail "Valid request failed"
assertCallCount 1
assertEqual "$(/bin/cat -- "${curlConfigFile}")" \
    "url = \"https://fleet.example.invalid/api/v1/fleet/device/${syntheticTokenA}/software\"" \
    "Incorrect config-stream URL"
arguments="$(<"${curlArgumentsFile}")"
[[ "${arguments}" != *"${syntheticTokenA}"* && "${arguments}" != *"https://"* ]] \
    || fail "Credential or request URL appeared in process arguments"
localArguments=("${(@f)arguments}")
assertEqual "${localArguments[1]}" "-q" "curl user configuration was not disabled first"
for forbiddenArgument in --location -L --retry --retry-all-errors --insecure -k --verbose -v --show-error -S; do
    (( ! ${localArguments[(Ie)${forbiddenArgument}]} )) || fail "Unsafe curl option ${forbiddenArgument}"
done
assertEqual "$(fleetJSONValue "${fleetResponse}" ok)" true "Native JSON extraction failed"

resetCase "token rotation is reread"
fleetRequest GET "/software" || fail "First token request failed"
print -r -- "${syntheticTokenB}" > "${fleetOrbitRoot}/identifier"
fleetRequest GET "/software" || fail "Rotated token request failed"
assertCallCount 2
[[ "$(<"${curlConfigFile}")" == *"${syntheticTokenB}/software"* ]] || fail "Rotated token was not read"
[[ "$(<"${curlArgumentsFile}")" != *"${syntheticTokenB}"* ]] || fail "Rotated token appeared in argv"

resetCase "local plist discovery"
fleetURL=""
print -r -- '{"EnvironmentVariables":{"ORBIT_FLEET_URL":"https://plist.example.invalid/"}}' > "${launchDaemonFixture}"
fleetReadDeviceURL || fail "Synthetic launch daemon URL was not discovered"
assertEqual "${fleetDeviceBaseURL}" "https://plist.example.invalid/api/v1/fleet/device/${syntheticTokenA}" "Wrong discovered server"

resetCase "local URL file fallback"
fleetURL=""
print -r -- "https://fallback.example.invalid:8443/" > "${fleetOrbitRoot}/fleet_url.txt"
fleetReadDeviceURL || fail "Synthetic URL file was not discovered"
assertEqual "${fleetDeviceBaseURL}" "https://fallback.example.invalid:8443/api/v1/fleet/device/${syntheticTokenA}" "Wrong fallback server"

for rejectedURL in "http://fleet.example.invalid" "https://user:password@fleet.example.invalid" \
    "https://fleet.example.invalid/path" "https://fleet.example.invalid?query=yes" \
    $'https://fleet.example.invalid"\ninsecure = true'; do
    resetCase "reject unsafe server URL"
    fleetURL="${rejectedURL}"
    if fleetRequest GET "/software"; then fail "Unsafe server URL was accepted"; fi
    assertCallCount 0
done

for rejectedToken in "" "not-a-desktop-token" $'11111111-1111-4111-8111-111111111111"\ninsecure = true'; do
    resetCase "reject invalid Desktop token"
    print -r -- "${rejectedToken}" > "${fleetOrbitRoot}/identifier"
    if fleetRequest GET "/software"; then fail "Invalid Desktop token was accepted"; fi
    assertCallCount 0
done

resetCase "accepted installation request"
mockCurlHTTPStatus=202
mockCurlBody='{}'
fleetRequest POST "/software/install/123" || fail "HTTP 202 request failed"
assertEqual "${fleetHTTPStatus}" 202 "HTTP 202 status was lost"
assertEqual "${fleetResponse}" '{}' "Response body was not separated from status"
assertCallCount 1

for rejectedHTTPStatus in 401 403 302 500; do
    resetCase "reject non-success HTTP response"
    mockCurlHTTPStatus="${rejectedHTTPStatus}"
    mockCurlBody='{"message":"request rejected"}'
    if fleetRequest POST "/software/install/123"; then fail "HTTP error was accepted"; fi
    assertEqual "${fleetHTTPStatus}" "${rejectedHTTPStatus}" "HTTP error status was lost"
    assertCallCount 1
done

resetCase "ambiguous POST failure is never retried"
mockCurlExitCode=28
mockCurlHTTPStatus=000
if fleetRequest POST "/software/install/123"; then fail "Transport timeout was accepted"; fi
assertCallCount 1
assertEqual "${fleetHTTPStatus}" "" "Failed transport retained an HTTP status"
assertEqual "${fleetResponse}" "" "Failed transport retained a response body"

resetCase "request timeout respects remaining deadline"
SECONDS=0
fleetDeadline=3
fleetRequest GET "/software" 30 || fail "Deadline-capped request failed"
arguments="$(<"${curlArgumentsFile}")"
localArguments=("${(@f)arguments}")
timeoutIndex=${localArguments[(Ie)--max-time]}
(( timeoutIndex > 0 )) || fail "No curl timeout supplied"
requestTimeout="${localArguments[$((timeoutIndex + 1))]}"
(( requestTimeout > 0 && requestTimeout <= 3 )) || fail "Request exceeded its remaining deadline"

resetCase "expired deadline prevents HTTP"
SECONDS=10
fleetDeadline=5
if fleetRequest POST "/software/install/123"; then fail "Expired deadline permitted a request"; fi
assertCallCount 0

resetCase "caller tracing does not expose token"
{
    setopt XTRACE
    fleetRequest GET "/software"
    unsetopt XTRACE
} > "${traceFile}" 2>&1 || fail "Traced request failed"
traceOutput="$(<"${traceFile}")"
[[ "${traceOutput}" != *"${syntheticTokenA}"* && "${traceOutput}" != *"${syntheticTokenB}"* ]] \
    || fail "Synthetic Desktop token leaked through shell tracing"
assertCallCount 1

print -r -- "PASS: ${testCount} native Fleet transport cases"
