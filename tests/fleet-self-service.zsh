#!/bin/zsh --no-rcs

# Native macOS plutil tests. Never source the entrypoint or contact Fleet.
setopt ERR_EXIT NO_UNSET PIPE_FAIL TYPESET_SILENT

repoRoot="${0:A:h:h}"
scriptPath="${repoRoot}/SYM-Lite.zsh"
temporaryDirectory="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/sym-lite-fleet-tests.XXXXXX")"
oldUUID="11111111-1111-4111-8111-111111111111"
newUUID="22222222-2222-4222-8222-222222222222"
otherUUID="33333333-3333-4333-8333-333333333333"
testName="setup"
testCount=0

function cleanup() { /bin/rm -rf -- "${temporaryDirectory}"; }
trap cleanup EXIT
function fail() { print -u2 -r -- "FAIL: ${testName}: $1"; exit 1; }
function assertEqual() { [[ "$1" == "$2" ]] || fail "$3 (got '$1', expected '$2')"; }

function loadProductionFunction() {
    local functionName="$1"
    local functionSource
    functionSource=$(/usr/bin/awk -v functionName="${functionName}" '
        capture && /^function / { exit }
        $0 == "function " functionName "() {" { capture = 1 }
        capture { print }
        # Inspect config contains a JSON heredoc with its own column-zero brace.
        capture && /^}$/ && functionName != "createSYMLiteInspectConfig" { exit }
    ' "${scriptPath}")
    [[ -n "${functionSource}" ]] || fail "Unable to extract ${functionName}"
    eval "${functionSource}"
}

for functionName in parseFleetSoftwareItem parseInstallomatorItem parseJamfPolicyItem \
    parseHomebrewItem fleetJSONValue fleetReadDeviceURL normalizeFleetSoftwareItems \
    isConfiguredFleetSoftwareItem fleetFindSoftwareTitle fleetReadInstallResult \
    fleetWaitForInstall executeFleetSoftwareItem fleetUpdateInspectStatus \
    isValidationPathPresent addCompletionReportRecord getItemType getItemConfig \
    getAllItemIDs getAllItemIDsCSV separateSelectedItemsByType escapeJSONString \
    getSelectionDialogStatusText getSelectionDialogLabel getSelectionDialogCheckboxesJSON \
    buildJSONStringArray createSYMLiteInspectConfig; do
    loadProductionFunction "${functionName}"
done

function preFlight() { :; }
function warning() { :; }
function notice() { :; }
function info() { :; }
function errorOut() { errors+=("$*"); }
function fatal() { fail "$*"; }

# Ordered response fixtures replace only HTTP. JSON parsing and orchestration are real.
function resetCase() {
    testName="$1"
    expectedRequests=(); responseBodies=(); responseStatuses=(); responsePaths=(); requests=()
    completedItems=(); skippedItems=(); failedItems=(); completionReportRecords=(); errors=()
    requestIndex=0
    repeatLastResponse=false
    fleetResponse=""; fleetHTTPStatus=""; fleetTitleJSON=""; fleetInstallStatus=""
    fleetExecutionFailed=false
    fleetInstallTimeout=3
    fleetPollInterval=1
    operationMode="silent"
    dialogCommandFile=""
    selectedItems=(fleet:123)
    mainDialogIcon=""
    SECONDS=0
    ((testCount += 1))
}

function queueResponse() {
    expectedRequests+=("$1 $2")
    responseStatuses+=("$3")
    responseBodies+=("$4")
    responsePaths+=("${5:-}")
}

function fleetRequest() {
    local request="$1 $2"
    local fixtureIndex
    requests+=("${request}")
    ((requestIndex += 1))
    fixtureIndex=${requestIndex}
    if (( fixtureIndex > ${#expectedRequests} )); then
        [[ "${repeatLastResponse}" == true ]] || fail "Unexpected request: ${request}"
        fixtureIndex=${#expectedRequests}
    fi
    assertEqual "${request}" "${expectedRequests[fixtureIndex]}" "HTTP request sequence"
    assertEqual "${#completedItems}" 0 "Marked complete before a verified result"
    fleetResponse="${responseBodies[fixtureIndex]}"
    fleetHTTPStatus="${responseStatuses[fixtureIndex]}"
    if [[ -n "${responsePaths[fixtureIndex]}" ]]; then
        [[ "${responsePaths[fixtureIndex]}" == "${temporaryDirectory}/"* ]] || fail "Fixture path escaped temporary directory"
        /usr/bin/touch "${responsePaths[fixtureIndex]}"
    fi
    [[ "${fleetHTTPStatus}" == 2[0-9][0-9] ]]
}

# Intercept the exact production sleep command; deadlines advance without wall-clock waits.
function /bin/sleep() {
    (( $1 > 0 && $1 <= fleetInstallTimeout )) || fail "Unbounded polling sleep"
    (( SECONDS += $1 ))
}

function catalogSuffix() {
    print -r -- "/software?self_service=true&per_page=100&page=${1:-0}&order_key=name&order_direction=asc"
}

function catalog() {
    local uuid="${1:-}"
    local titleID="${2:-123}"
    local lastInstall=null
    [[ -z "${uuid}" ]] || lastInstall="{\"install_uuid\":\"${uuid}\",\"installed_at\":\"2026-09-15T12:00:00Z\"}"
    print -r -- "{\"software\":[{\"id\":${titleID},\"name\":\"Fixture script\",\"source\":\"sh_packages\",\"status\":\"installed\",\"installed_versions\":[],\"software_package\":{\"self_service\":true,\"last_install\":${lastInstall}},\"app_store_app\":null}],\"meta\":{\"has_next_results\":false}}"
}

function result() {
    print -r -- "{\"results\":{\"install_uuid\":\"$1\",\"software_title_id\":${3:-123},\"self_service\":true,\"status\":\"$2\",\"output\":\"fixture output\"}}"
}

function queueNewInstall() {
    queueResponse GET "$(catalogSuffix)" 200 "$(catalog)"
    queueResponse POST /software/install/123 202 '{}'
    queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${newUUID}")"
}

function expectSuccess() {
    executeFleetSoftwareItem fleet:123 "${1:-}" "Fixture script" "" || fail "Expected success: ${errors[*]}"
    assertEqual "${#completedItems}" 1 "Completed item count"
    assertEqual "${#failedItems}" 0 "Failed item count"
    assertEqual "${fleetExecutionFailed}" false "Successful item set failure exit flag"
}

function expectFailure() {
    if executeFleetSoftwareItem fleet:123 "${1:-}" "Fixture script" ""; then
        fail "Expected failure"
    fi
    assertEqual "${#completedItems}" 0 "Unexpected success"
    assertEqual "${#failedItems}" 1 "Failed item count"
    assertEqual "${fleetExecutionFailed}" true "Failed item did not set failure exit flag"
}

resetCase "script-only package waits for Fleet result without a validation marker"
queueNewInstall
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" pending_install)"
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed)"
expectSuccess
assertEqual "${requestIndex}" 5 "Did not poll through pending result"
assertEqual "${SECONDS}" 1 "Pending result did not wait"

resetCase "accepted POST with no new attempt cannot succeed"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog)"
queueResponse POST /software/install/123 202 '{}'
queueResponse GET "$(catalogSuffix)" 200 "$(catalog)"
repeatLastResponse=true
expectFailure
assertEqual "${SECONDS}" "${fleetInstallTimeout}" "Timeout was not bounded"
[[ "${errors[*]}" == *"Timed out"* ]] || fail "Missing timeout diagnostic"

resetCase "stale successful attempt cannot confirm the new POST"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${oldUUID}")"
queueResponse GET "/software/install/${oldUUID}/results" 200 "$(result "${oldUUID}" installed)"
queueResponse POST /software/install/123 202 '{}'
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${oldUUID}")"
repeatLastResponse=true
expectFailure

resetCase "new attempt supersedes old success"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${oldUUID}")"
queueResponse GET "/software/install/${oldUUID}/results" 200 "$(result "${oldUUID}" installed)"
queueResponse POST /software/install/123 202 '{}'
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${oldUUID}")"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${newUUID}")"
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed)"
expectSuccess

resetCase "existing pending attempt is reused without POST"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${oldUUID}")"
queueResponse GET "/software/install/${oldUUID}/results" 200 "$(result "${oldUUID}" pending_install)"
queueResponse GET "/software/install/${oldUUID}/results" 200 "$(result "${oldUUID}" installed)"
expectSuccess
assertEqual "${requestIndex}" 3 "Existing attempt should need no POST or catalog repoll"

resetCase "failed script-only result fails the item"
queueNewInstall
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" failed_install)"
expectFailure
[[ "${errors[*]}" == *"Fleet reported a failed install"* ]] || fail "Missing failure diagnostic"

for mismatch in uuid title; do
    resetCase "mismatched ${mismatch} cannot confirm success"
    queueNewInstall
    if [[ "${mismatch}" == uuid ]]; then
        queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${otherUUID}" installed)"
    else
        queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed 456)"
    fi
    repeatLastResponse=true
    expectFailure
done

resetCase "missing configured path fails after Fleet success"
queueNewInstall
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed)"
expectFailure "${temporaryDirectory}/missing-marker"
[[ "${errors[*]}" == *"validation path is missing"* ]] || fail "Missing postvalidation diagnostic"

resetCase "configured path is checked after successful Fleet execution"
queueNewInstall
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed)" "${temporaryDirectory}/created-marker"
expectSuccess "${temporaryDirectory}/created-marker"
assertEqual "${#skippedItems}" 0 "Path postvalidation skipped execution"

resetCase "existing validation path skips before network access"
/usr/bin/touch "${temporaryDirectory}/existing-marker"
executeFleetSoftwareItem fleet:123 "${temporaryDirectory}/existing-marker" "Fixture script" "" || fail "Expected skip"
assertEqual "${requestIndex}" 0 "Skipped item contacted Fleet"
assertEqual "${#skippedItems}" 1 "Skipped item count"
assertEqual "${#completedItems}" 0 "Skipped item marked newly installed"

resetCase "unavailable title is rejected without POST"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog '' 456)"
expectFailure
assertEqual "${requestIndex}" 1 "Unavailable title requested installation"

resetCase "App Store title is rejected without POST"
queueResponse GET "$(catalogSuffix)" 200 '{"software":[{"id":123,"software_package":null,"app_store_app":{"self_service":true}}],"meta":{"has_next_results":false}}'
expectFailure
assertEqual "${requestIndex}" 1 "App Store title requested installation"

resetCase "catalog pagination finds exact title ID"
queueResponse GET "$(catalogSuffix)" 200 '{"software":[{"id":1234}],"meta":{"has_next_results":true}}'
queueResponse GET "$(catalogSuffix 1)" 200 "$(catalog)"
queueResponse POST /software/install/123 202 '{}'
queueResponse GET "$(catalogSuffix)" 200 "$(catalog "${newUUID}")"
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed)"
expectSuccess

for deniedStatus in 401 403; do
    resetCase "HTTP ${deniedStatus} denial fails without retry"
    queueResponse GET "$(catalogSuffix)" "${deniedStatus}" '{"message":"Access denied","sso_required":true}'
    expectFailure
    assertEqual "${requestIndex}" 1 "Denied request was retried"
done

resetCase "POST response loss does not retry installation"
queueResponse GET "$(catalogSuffix)" 200 "$(catalog)"
queueResponse POST /software/install/123 000 ''
expectFailure
assertEqual "${requestIndex}" 2 "Ambiguous POST was retried"

resetCase "polling auth denial ends immediately"
queueNewInstall
queueResponse GET "/software/install/${newUUID}/results" 401 '{"sso_required":true}'
expectFailure
assertEqual "${SECONDS}" 0 "Auth denial continued polling"

resetCase "invalid catalog fails closed"
queueResponse GET "$(catalogSuffix)" 200 '<html>proxy error</html>'
expectFailure
assertEqual "${requestIndex}" 1 "Malformed catalog requested installation"

resetCase "Fleet parser preserves empty validation path and mixed item routing"
fleetSoftwareItems=("fleet:123 | Fleet script |  | https://example.invalid/script.png")
parseFleetSoftwareItem "${fleetSoftwareItems[1]}"
assertEqual "${itemFleetTitleID}" 123 "Parsed title ID"
assertEqual "${itemValidationPath}" '' "Empty validation path shifted fields"
assertEqual "${itemIconURL}" https://example.invalid/script.png "Parsed icon"
installomatorLabels=("chrome | Browser | /nonexistent/Browser.app | ")
jamfPolicyItems=("jamf-test | Jamf action | /nonexistent/Jamf.marker | ")
homebrewItems=("formula:jq | jq | /nonexistent/jq | ")
selectedItems=(chrome fleet:123 jamf-test formula:jq)
separateSelectedItemsByType
assertEqual "${selectedFleetSoftwareItems[*]}" fleet:123 "Fleet dispatch"
assertEqual "${selectedInstallomatorLabels[*]}" chrome "Installomator dispatch"
assertEqual "${selectedJamfPolicies[*]}" jamf-test "Jamf dispatch"
assertEqual "${selectedHomebrewItems[*]}" formula:jq "Homebrew dispatch"
assertEqual "$(getItemConfig fleet:123)" "${fleetSoftwareItems[1]}" "Fleet config lookup"
assertEqual "$(getAllItemIDsCSV)" chrome,jamf-test,formula:jq,fleet:123 "Mixed CSV inventory"
selectionDialogStatusSublabelsEnabled=true
selectionDialogDefaultChecked=true
getSelectionDialogCheckboxesJSON || fail "Picker generation failed"
/usr/bin/plutil -convert json -o - - >/dev/null <<< "${selectionDialogCheckboxesJSON}" || fail "Invalid picker JSON"
[[ "${selectionDialogCheckboxesJSON}" == *'Validated by Fleet'* ]] || fail "Missing Fleet completion label"
assertEqual "${selectionDialogTotalItemCount}" 4 "Mixed picker item count"
assertEqual "${selectionDialogDisabledItemCount}" 0 "Script-only Fleet item was disabled"
assertEqual "$(fleetJSONValue "${selectionDialogCheckboxesJSON}" 1.name)" fleet:123 "Picker preserved namespaced Fleet ID"

resetCase "Inspect receives indexed wait and completion updates"
operationMode=interactive
selectedItems=(formula:jq fleet:123)
dialogCommandFile="${temporaryDirectory}/inspect-commands"
queueNewInstall
queueResponse GET "/software/install/${newUUID}/results" 200 "$(result "${newUUID}" installed)"
expectSuccess
inspectCommands=$(<"${dialogCommandFile}")
[[ "${inspectCommands}" == *'listitem: index: 1, status: wait, statustext: Waiting for Fleet'* ]] || fail "Missing indexed waiting update"
[[ "${inspectCommands}" == *'listitem: index: 1, status: success, statustext: Completed'* ]] || fail "Missing confirmed completion update"

resetCase "mixed Inspect config cannot auto-complete Fleet from another item's path or log"
# Keep the builder's file creation in the test directory instead of /var/tmp.
function /usr/bin/mktemp() { command /usr/bin/mktemp "${temporaryDirectory}/inspect.XXXXXX"; }
organizationScriptName=FleetRegressionTest
organizationPreset=1
organizationOverlayiconURL=""
installomatorLog="${temporaryDirectory}/Installomator.log"
loggedInUserHomeDirectory=""
installomatorLabels=("chrome | Shared name | /Applications/Fixture.app | ")
fleetSoftwareItems=("fleet:123 | Shared name | /Applications/Fixture.app | ")
jamfPolicyItems=(); homebrewItems=()
selectedItems=(chrome fleet:123)
separateSelectedItemsByType
createSYMLiteInspectConfig || fail "Mixed Inspect config generation failed"
inspectJSON=$(<"${dialogInspectModeJSONFile}")
assertEqual "$(fleetJSONValue "${inspectJSON}" items.1.id)" fleet:123 "Fleet Inspect item ID"
assertEqual "$(fleetJSONValue "${inspectJSON}" items.0.displayName)" "$(fleetJSONValue "${inspectJSON}" items.1.displayName)" "Same-name regression fixture"
assertEqual "$(/usr/bin/plutil -extract items.1.paths json -o - "${dialogInspectModeJSONFile}")" '[]' "Fleet paths must not drive completion"
assertEqual "$(fleetJSONValue "${inspectJSON}" items.0.paths.0)" /Applications/Fixture.app "Installomator path monitoring preserved"
if /usr/bin/plutil -extract logMonitor json -o - "${dialogInspectModeJSONFile}" >/dev/null 2>&1; then
    fail "Mixed Inspect config enabled global log matching"
fi

resetCase "Installomator-only Inspect config retains original log auto-match"
selectedItems=(chrome)
separateSelectedItemsByType
createSYMLiteInspectConfig || fail "Installomator Inspect config generation failed"
inspectJSON=$(<"${dialogInspectModeJSONFile}")
assertEqual "$(fleetJSONValue "${inspectJSON}" logMonitor.autoMatch)" true "Installomator auto-match removed"
assertEqual "$(fleetJSONValue "${inspectJSON}" logMonitor.preset)" installomator "Log parser preset changed"
assertEqual "$(fleetJSONValue "${inspectJSON}" logMonitor.path)" "${installomatorLog}" "Log path changed"

resetCase "Fleet normalization rejects malformed and duplicate configurations"
fleetURL=https://example.invalid
fleetOrbitRoot="${temporaryDirectory}"
print -rn -- "${oldUUID}" > "${fleetOrbitRoot}/identifier"
enableFleetSoftwareItems=true
configuredFleetSoftwareItems=(
    "fleet:123 | Good script |  | "
    "fleet:123 | Duplicate script |  | "
    "fleet:0 | Zero title |  | "
    "fleet:nope | Text title |  | "
    "fleet:456 | Relative path | relative/marker | "
)
normalizeFleetSoftwareItems || fail "Normalization returned error"
assertEqual "${#fleetSoftwareItems}" 1 "Invalid or duplicate item accepted"
assertEqual "${fleetSoftwareItems[1]}" "${configuredFleetSoftwareItems[1]}" "Valid configuration changed"
enableFleetSoftwareItems=false
normalizeFleetSoftwareItems || fail "Disabled normalization returned error"
assertEqual "${#fleetSoftwareItems}" 0 "Disabled Fleet items remain available"

print -r -- "PASS: ${testCount} Fleet self-service regression cases (mock HTTP, native plutil)"
