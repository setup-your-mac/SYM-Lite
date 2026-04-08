#!/bin/zsh --no-rcs
# shellcheck shell=bash

####################################################################################################
#
# SYM-Lite
#
# - Lean, purpose-built script for executing Jamf Pro Policy Custom Triggers and Installomator labels
# - User selects which items to install/execute via swiftDialog selection UI
# - Monitors execution progress via swiftDialog Inspect Mode
# - No user input prompts beyond selection (no asset tag, computer name, etc.)
#
# https://snelson.us/sym
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0b5, 08-Apr-2026, Dan K. Snelson (@dan-snelson)
# - Added pre-flight validation for configured Installomator labels against the active Installomator file.
# - Filtered unavailable Installomator labels out of the interactive picker, silent-mode CSV parsing, and runtime lookups.
# - Updated the no-selectable-items dialog so filtered labels do not appear as already installed.
# - Refined Installomator dependency handling to fail fast when the configured file is unusable.
# - Updated release documentation for early Installomator label validation.
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
setopt NONOMATCH
setopt TYPESET_SILENT

# Script Version
scriptVersion="1.0.0b5"

# Script Human-readable Name
humanReadableScriptName="Setup Your Mac Lite: Developer Edition"

# Organization's Script Name
organizationScriptName="SYML"

# Client-side Log
scriptLog="/var/log/org.churchofjesuschrist.log"

# Installomator Log
installomatorLog="/var/log/Installomator.log"

# Elapsed Time
SECONDS="0"

# Minimum Required Version of swiftDialog
swiftDialogMinimumRequiredVersion="3.0.1.4955"

# Load is-at-least for version comparison
autoload -Uz is-at-least



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Runtime Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Runtime inputs (Jamf parameters by default; CLI flags can override)
operationMode="${4:-"interactive"}"     # Parameter 4: Operation Mode [ interactive (default) | silent ]
operationsCSV="${5:-""}"                # Parameter 5: Comma-separated list of item IDs for silent mode



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Organization's swiftDialog Inspect Mode Preset Option (See: https://swiftdialog.app/advanced/inspect-mode/)
organizationPreset="2"

# Organization's Installomator Path
organizationInstallomatorFile="/Library/Management/AppAutoPatch/Installomator/Installomator.sh"

# Organization's Jamf Binary Path
jamfBinary="/usr/local/bin/jamf"

# Enable or disable Jamf policy items
enableJamfPolicyItems="true"

# Organization's Overlayicon URL
organizationOverlayiconURL="https://swiftdialog.app/_astro/dialog_logo.CZF0LABZ_ZjWz8w.webp"

# Main Dialog Icon
mainDialogIcon="https://raw.githubusercontent.com/setup-your-mac/Setup-Your-Mac/refs/heads/main/images/SYM_icon.png"

# Dialog presentation defaults
fontSize="14"
selectionDialogStatusSublabelsEnabled="true"

# Restart prompt behavior
restartPromptEnabled="true"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Item Configuration Arrays
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Installomator Labels
# Format: "label | Display Name | Validation Path | Icon URL"
installomatorLabels=(
    "androidstudio | Android Studio | /Applications/Android Studio.app | https://use2.ics.services.jamfcloud.com/icon/hash_f7021d808263d18f52ba2535ec66d35f8bb24b08ab9bff6aee22ecb319159904"
    "awsvpnclient | AWS VPN Client | /Applications/AWS VPN Client/AWS VPN Client.app | https://usw2.ics.services.jamfcloud.com/icon/hash_1d1bef5523d9f7eca5a45f2db9a63732e85edb5f914220807ca740ba7c4881b9"
    "bruno | Bruno | /Applications/Bruno.app | https://usw2.ics.services.jamfcloud.com/icon/hash_48501630ad2f5dd5de3e055d6acdda07682895440cad366ee7befac71cab1399"
    "charles | Charles Proxy | /Applications/Charles.app | https://use2.ics.services.jamfcloud.com/icon/hash_59b395ca81889a6d83deda8e6babc5ae4bc5931d36a72b738fe30b84d027593d"
    "docker | Docker | /Applications/Docker.app | https://usw2.ics.services.jamfcloud.com/icon/hash_a344dca5fdc0e86822e8f21ec91088e6591b1e292bdcebdee1281fbd794c2724"
    "jetbrainsintellijidea | IntelliJ IDEA | /Applications/IntelliJ IDEA.app | https://usw2.ics.services.jamfcloud.com/icon/hash_f669d73acc06297e1fc2f65245cfbdace03263f81aebf95444a8360a101b239d"
    "pique | Pique | /Applications/Pique.app | https://usw2.ics.services.jamfcloud.com/icon/hash_7d2539860cca6ec5ea5a71cba2aee7d93b9534e4267c16f73c7035f3dc025b9c"
    "visualstudiocode | Visual Studio Code | /Applications/Visual Studio Code.app | https://use2.ics.services.jamfcloud.com/icon/hash_532094f99f6130f325a97ed6421d09d2a416e269f284304d39c21020565056ed"
)

configuredInstallomatorLabels=("${installomatorLabels[@]}")

# Jamf Pro Policies
# Format: "trigger | Display Name | Validation Path | Icon URL"
jamfPolicyItems=(
    "appleXcode | Xcode | /Applications/Xcode.app | https://usw2.ics.services.jamfcloud.com/icon/hash_583afb5af440479d642b3c35ec4ec3ad06c74ec814dba9af84e4e69202edf62a"
    "homebrew | Homebrew | /opt/homebrew/bin/brew | https://usw2.ics.services.jamfcloud.com/icon/hash_9edff3eb98482a1aaf17f8560488f7b500cc7dc64955b8a9027b3801cab0fd82"
)

configuredJamfPolicyItems=("${jamfPolicyItems[@]}")


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# swiftDialog Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# swiftDialog Binary Path
dialogBinary="/usr/local/bin/dialog"

# swiftDialog App Bundle
dialogAppBundle="/Library/Application Support/Dialog/Dialog.app"

# swiftDialog Inspect Mode JSON File
dialogInspectModeJSONFile=""



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Runtime Tracking Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selectedItems=()
selectedInstallomatorLabels=()
selectedJamfPolicies=()
failedItems=()
completedItems=()
skippedItems=()
completionReportRecords=()
completionDialogJSONFile=""
dialogPID=""
dialogTemporaryDirectory=""
selectionDialogOptionRecords=()
selectionDialogTotalItemCount=0
selectionDialogDisabledItemCount=0
selectionDialogCheckboxesJSON=""



####################################################################################################
#
# Logging Helpers
#
####################################################################################################

function updateScriptLog() {
    local level="$1"
    local message="$2"
    echo "${organizationScriptName} (${scriptVersion}): $(date '+%Y-%m-%d %H:%M:%S')  [${level}] ${message}" | tee -a "${scriptLog}" >&2
}

function preFlight()    { updateScriptLog "PRE-FLIGHT" "${1}"; }
function logComment()   { updateScriptLog "INFO" "${1}"; }
function notice()       { updateScriptLog "NOTICE" "${1}"; }
function info()         { updateScriptLog "INFO" "${1}"; }
function warning()      { updateScriptLog "WARNING" "${1}"; }
function errorOut()     { updateScriptLog "ERROR" "${1}"; }
function fatal()        { updateScriptLog "FATAL ERROR" "${1}"; exit 10; }

function cleanup() {
    if [[ -n "${dialogInspectModeJSONFile}" && -e "${dialogInspectModeJSONFile}" ]]; then
        rm -f -- "${dialogInspectModeJSONFile}" 2>/dev/null
        dialogInspectModeJSONFile=""
    fi

    if [[ -n "${completionDialogJSONFile}" && -e "${completionDialogJSONFile}" ]]; then
        rm -f -- "${completionDialogJSONFile}" 2>/dev/null
        completionDialogJSONFile=""
    fi

    if [[ -n "${dialogTemporaryDirectory}" && -d "${dialogTemporaryDirectory}" ]]; then
        case "${dialogTemporaryDirectory}" in
            /tmp/*|/var/tmp/*|/private/tmp/*)
                rm -rf -- "${dialogTemporaryDirectory}" 2>/dev/null
                ;;
        esac
    fi
}
trap cleanup EXIT



####################################################################################################
#
# Core Helper Functions
#
####################################################################################################

function currentLoggedInUser() {
    local shouldLog="${1:-true}"

    loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )

    if [[ "${shouldLog}" == "true" ]]; then
        preFlight "Current Logged-in User: ${loggedInUser}"
    fi
}

function updateLoggedInUserDetails() {
    loggedInUserFullname=$( /usr/bin/id -F "${loggedInUser}" )
    loggedInUserFirstname=$( /bin/echo "${loggedInUserFullname}" | /usr/bin/sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | /usr/bin/sed 's/\(.\{25\}\).*/\1…/' | /usr/bin/awk '{print ( $0 == toupper($0) ? toupper(substr($0,1,1))substr(tolower($0),2) : toupper(substr($0,1,1))substr($0,2) )}' )
    loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )
    loggedInUserHomeDirectory=$( /usr/bin/dscl . read "/Users/${loggedInUser}" NFSHomeDirectory | /usr/bin/awk -F ' ' '{ print $2 }' )
}

function requireLoggedInUser() {
    local context="${1:-perform a UI action}"

    currentLoggedInUser "false"

    if [[ -z "${loggedInUser}" || "${loggedInUser}" == "loginwindow" ]]; then
        fatal "No valid logged-in GUI user detected; cannot ${context}."
    fi

    if ! /usr/bin/id -u "${loggedInUser}" >/dev/null 2>&1; then
        fatal "Logged-in GUI user '${loggedInUser}' is not resolvable; cannot ${context}."
    fi

    updateLoggedInUserDetails
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {
    local user="$1"
    shift
    local userID=""
    local rc=0

    if [[ -z "${user}" ]]; then
        "$@"
        return $?
    fi

    userID="$(id -u "${user}" 2>/dev/null)"
    if [[ "${userID}" =~ ^[0-9]+$ ]]; then
        /bin/launchctl asuser "${userID}" /usr/bin/sudo -u "${user}" "$@"
        rc=$?
        [[ ${rc} -eq 0 ]] && return 0
    fi

    /usr/bin/sudo -u "${user}" "$@"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Installomator Item Configuration
# Input: "label | displayName | validationPath | iconURL"
# Output: Sets global variables itemLabel, itemDisplayName, itemValidationPath, itemIconURL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseInstallomatorItem() {
    local itemConfig="$1"
    local parts=("${(@s: | :)itemConfig}")

    itemLabel="${parts[1]}"
    itemDisplayName="${parts[2]}"
    itemValidationPath="${parts[3]}"
    itemIconURL="${parts[4]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Jamf Policy Item Configuration
# Input: "trigger | displayName | validationPath | iconURL"
# Output: Sets global variables itemTrigger, itemDisplayName, itemValidationPath, itemIconURL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseJamfPolicyItem() {
    local itemConfig="$1"
    local parts=("${(@s: | :)itemConfig}")

    itemTrigger="${parts[1]}"
    itemDisplayName="${parts[2]}"
    itemValidationPath="${parts[3]}"
    itemIconURL="${parts[4]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Selection Dialog Status Text
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getSelectionDialogStatusText() {
    local validationPath="$1"

    if isValidationPathPresent "${validationPath}"; then
        print -r -- "Already installed"
    else
        print -r -- "New installation"
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Selection Dialog Label
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getSelectionDialogLabel() {
    local displayName="$1"
    local validationPath="$2"
    local itemStatusText=""

    if [[ "${selectionDialogStatusSublabelsEnabled:l}" == "true" ]]; then
        itemStatusText=$(getSelectionDialogStatusText "${validationPath}")
        print -r -- "${displayName}"$'\n'"${itemStatusText}"
    else
        print -r -- "${displayName}"
    fi
}

function getSelectionDialogCheckboxesJSON() {
    local -a allSortKeys=()
    local -a usedCheckboxLabels=()
    local item=""
    local entry=""
    local checkboxItemsJSON=""
    local separator=""
    local checkboxLabel=""
    local escapedCheckboxLabel=""
    local escapedIconURL=""
    local checkboxDisabled="false"
    local itemID=""
    local existingLabel=""
    local escapedItemID=""

    selectionDialogOptionRecords=()
    selectionDialogTotalItemCount=0
    selectionDialogDisabledItemCount=0

    for item in "${installomatorLabels[@]}"; do
        local parts=("${(@s: | :)item}")
        allSortKeys+=("${parts[2]} | installomator | ${item}")
    done
    for item in "${jamfPolicyItems[@]}"; do
        local parts=("${(@s: | :)item}")
        allSortKeys+=("${parts[2]} | jamf | ${item}")
    done

    for entry in "${(oi)allSortKeys[@]}"; do
        ((selectionDialogTotalItemCount++))
        local entryParts=("${(@s: | :)entry}")
        local itemType="${entryParts[2]}"
        local itemConfig="${(j: | :)entryParts[3,-1]}"

        if [[ "${itemType}" == "installomator" ]]; then
            parseInstallomatorItem "${itemConfig}"
            itemID="${itemLabel}"
        else
            parseJamfPolicyItem "${itemConfig}"
            itemID="${itemTrigger}"
        fi

        checkboxLabel=$(getSelectionDialogLabel "${itemDisplayName}" "${itemValidationPath}")
        for existingLabel in "${usedCheckboxLabels[@]}"; do
            if [[ "${existingLabel}" == "${checkboxLabel}" ]]; then
                checkboxLabel="${checkboxLabel} (${itemID})"
                break
            fi
        done
        usedCheckboxLabels+=("${checkboxLabel}")

        if [[ "${selectionDialogStatusSublabelsEnabled:l}" == "true" ]] && isValidationPathPresent "${itemValidationPath}"; then
            checkboxDisabled="true"
            ((selectionDialogDisabledItemCount++))
        else
            checkboxDisabled="false"
            selectionDialogOptionRecords+=("${itemID}")
        fi

        escapedCheckboxLabel=$(escapeJSONString "${checkboxLabel}")
        escapedItemID=$(escapeJSONString "${itemID}")
        escapedIconURL=$(escapeJSONString "${itemIconURL}")
        checkboxItemsJSON="${checkboxItemsJSON}${separator}{\"label\":\"${escapedCheckboxLabel}\",\"name\":\"${escapedItemID}\",\"checked\":false,\"disabled\":${checkboxDisabled},\"icon\":\"${escapedIconURL}\"}"
        separator=","
    done

    selectionDialogCheckboxesJSON="[${checkboxItemsJSON}]"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Available Installomator Labels
# Parses the active Installomator file for top-level case arms under `case $label in`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getAvailableInstallomatorLabels() {
    local -a availableLabels=()
    local -A availableLabelMap=()
    local labelArmsOutput=""
    local labelArm=""
    local labelAlias=""

    if ! labelArmsOutput=$(/usr/bin/awk '
        BEGIN {
            inLabelCase = 0
            caseDepth = 0
        }

        /^[[:space:]]*case[[:space:]]+\$label[[:space:]]+in[[:space:]]*$/ {
            inLabelCase = 1
            caseDepth = 1
            next
        }

        inLabelCase {
            if ($0 ~ /^[[:space:]]*case[[:space:]].*[[:space:]]+in[[:space:]]*$/) {
                caseDepth++
                next
            }

            if ($0 ~ /^[[:space:]]*esac([[:space:]]*;.*)?[[:space:]]*$/) {
                caseDepth--
                if (caseDepth == 0) {
                    exit
                }
                next
            }

            if (caseDepth == 1 && $0 ~ /^[[:space:]]*[A-Za-z0-9_*][A-Za-z0-9_|-]*\)[[:space:]]*$/) {
                labelArm = $0
                sub(/^[[:space:]]*/, "", labelArm)
                sub(/\)[[:space:]]*$/, "", labelArm)
                print labelArm
            }
        }
    ' "${organizationInstallomatorFile}"); then
        return 1
    fi

    while IFS= read -r labelArm; do
        [[ -z "${labelArm}" ]] && continue

        for labelAlias in "${(@s:|:)labelArm}"; do
            labelAlias="${labelAlias// /}"

            case "${labelAlias}" in
                longversion|valuesfromarguments|'*')
                    continue
                    ;;
            esac

            if (( ! ${+availableLabelMap[$labelAlias]} )); then
                availableLabelMap[$labelAlias]=1
                availableLabels+=("${labelAlias}")
            fi
        done
    done <<< "${labelArmsOutput}"

    print -l -- "${availableLabels[@]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Normalize Installomator Label Availability
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function normalizeInstallomatorLabels() {
    local configuredLabelCount="${#configuredInstallomatorLabels[@]}"
    local -a normalizedInstallomatorLabels=()
    local -a availableInstallomatorLabels=()
    local -A availableInstallomatorLabelMap=()
    local availableLabelsOutput=""
    local item=""
    local label=""
    local displayName=""
    local filteredLabelCount=0
    local availableLabel=""

    if [[ ${configuredLabelCount} -eq 0 ]]; then
        installomatorLabels=()
        preFlight "No Installomator labels configured"
        return 0
    fi

    if [[ ! -e "${organizationInstallomatorFile}" ]]; then
        fatal "Installomator not found at ${organizationInstallomatorFile}"
    elif [[ ! -f "${organizationInstallomatorFile}" ]]; then
        fatal "Installomator is not a regular file at ${organizationInstallomatorFile}"
    elif [[ ! -r "${organizationInstallomatorFile}" ]]; then
        fatal "Installomator is not readable at ${organizationInstallomatorFile}"
    elif [[ ! -x "${organizationInstallomatorFile}" ]]; then
        fatal "Installomator is not executable at ${organizationInstallomatorFile}"
    elif [[ ! -s "${organizationInstallomatorFile}" ]]; then
        fatal "Installomator at ${organizationInstallomatorFile} is zero bytes"
    fi

    preFlight "Installomator found at ${organizationInstallomatorFile}; validating configured labels"

    if ! availableLabelsOutput="$(getAvailableInstallomatorLabels)"; then
        fatal "Failed to parse Installomator labels from ${organizationInstallomatorFile}"
    fi

    availableInstallomatorLabels=("${(@f)availableLabelsOutput}")

    if [[ ${#availableInstallomatorLabels[@]} -eq 0 ]]; then
        fatal "No Installomator labels were parsed from ${organizationInstallomatorFile}; verify the file format matches Installomator's label case statement"
    fi

    for availableLabel in "${availableInstallomatorLabels[@]}"; do
        availableInstallomatorLabelMap[$availableLabel]=1
    done

    for item in "${configuredInstallomatorLabels[@]}"; do
        parseInstallomatorItem "${item}"
        label="${itemLabel}"
        displayName="${itemDisplayName}"

        if (( ${+availableInstallomatorLabelMap[$label]} )); then
            normalizedInstallomatorLabels+=("${item}")
        else
            errorOut "Configured Installomator label '${label}' (${displayName}) is not available in ${organizationInstallomatorFile}; hiding it from this run"
            ((filteredLabelCount++))
        fi
    done

    installomatorLabels=("${normalizedInstallomatorLabels[@]}")
    preFlight "Installomator label validation complete: ${#installomatorLabels[@]} available, ${filteredLabelCount} filtered"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Normalize Jamf Policy Item Availability
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function normalizeJamfPolicyItems() {
    local jamfPolicyItemsSetting="${enableJamfPolicyItems:l}"

    if [[ "${jamfPolicyItemsSetting}" != "true" && "${jamfPolicyItemsSetting}" != "false" ]]; then
        warning "Invalid enableJamfPolicyItems value '${enableJamfPolicyItems}'; defaulting to true"
        enableJamfPolicyItems="true"
        jamfPolicyItemsSetting="true"
    fi

    if [[ "${jamfPolicyItemsSetting}" == "true" ]]; then
        jamfPolicyItems=("${configuredJamfPolicyItems[@]}")
    else
        jamfPolicyItems=()
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Configured Jamf Policy Item
# Input: Item ID
# Output: 0 if item exists in configuredJamfPolicyItems, 1 otherwise
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function isConfiguredJamfPolicyItem() {
    local itemID="$1"
    local item

    for item in "${configuredJamfPolicyItems[@]}"; do
        local parts=("${(@s: | :)item}")
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            return 0
        fi
    done

    return 1
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Configured Installomator Label
# Input: Item ID
# Output: 0 if item exists in configuredInstallomatorLabels, 1 otherwise
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function isConfiguredInstallomatorLabel() {
    local itemID="$1"
    local item

    for item in "${configuredInstallomatorLabels[@]}"; do
        local parts=("${(@s: | :)item}")
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            return 0
        fi
    done

    return 1
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get All Item IDs
# Returns: Array of all item identifiers (labels + triggers)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getAllItemIDs() {
    local allIDs=()
    
    # Add Installomator labels
    for item in "${installomatorLabels[@]}"; do
        local parts=("${(@s: | :)item}")
        allIDs+=("${parts[1]}")
    done
    
    # Add Jamf policy triggers
    for item in "${jamfPolicyItems[@]}"; do
        local parts=("${(@s: | :)item}")
        allIDs+=("${parts[1]}")
    done
    
    print -r -- "${allIDs[@]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Item Type
# Input: Item ID
# Output: "installomator" or "jamf" or empty string if not found
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getItemType() {
    local itemID="$1"
    
    # Check Installomator labels
    for item in "${installomatorLabels[@]}"; do
        local parts=("${(@s: | :)item}")
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            print -r -- "installomator"
            return 0
        fi
    done
    
    # Check Jamf policy items
    for item in "${jamfPolicyItems[@]}"; do
        local parts=("${(@s: | :)item}")
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            print -r -- "jamf"
            return 0
        fi
    done
    
    print -r -- ""
    return 1
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Item Configuration
# Input: Item ID
# Output: Full configuration string
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getItemConfig() {
    local itemID="$1"
    
    # Check Installomator labels
    for item in "${installomatorLabels[@]}"; do
        local parts=("${(@s: | :)item}")
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            print -r -- "${item}"
            return 0
        fi
    done
    
    # Check Jamf policy items
    for item in "${jamfPolicyItems[@]}"; do
        local parts=("${(@s: | :)item}")
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            print -r -- "${item}"
            return 0
        fi
    done
    
    print -r -- ""
    return 1
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Completion Report Helpers
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function escapeJSONString() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    print -r -- "${value}"
}

function isValidationPathPresent() {
    local validationPath="$1"

    [[ -n "${validationPath}" && -e "${validationPath}" ]]
}

function addCompletionReportRecord() {
    local displayName="$1"
    local statusKey="$2"
    local dialogStatus="$3"
    local iconURL="$4"
    local subtitle="$5"
    local statusText="$6"

    [[ -z "${iconURL}" ]] && iconURL="${mainDialogIcon}"

    completionReportRecords+=("${displayName}"$'\t'"${statusKey}"$'\t'"${dialogStatus}"$'\t'"${iconURL}"$'\t'"${subtitle}"$'\t'"${statusText}")
}

function buildCompletionReportListItemsJSON() {
    if [[ ${#completionReportRecords[@]} -eq 0 ]]; then
        print -r -- "[]"
        return 0
    fi

    local -a sortedRecords
    sortedRecords=("${(@f)$(printf '%s\n' "${completionReportRecords[@]}" | LC_ALL=C sort -f)}")

    local record=""
    local displayName=""
    local statusKey=""
    local dialogStatus=""
    local iconURL=""
    local subtitle=""
    local statusText=""
    local escapedDisplayName=""
    local escapedIconURL=""
    local escapedSubtitle=""
    local escapedStatusText=""
    local listItemsJSON=""
    local separator=""

    for record in "${sortedRecords[@]}"; do
        IFS=$'\t' read -r displayName statusKey dialogStatus iconURL subtitle statusText <<< "${record}"

        escapedDisplayName=$(escapeJSONString "${displayName}")
        escapedIconURL=$(escapeJSONString "${iconURL}")
        escapedSubtitle=$(escapeJSONString "${subtitle}")
        escapedStatusText=$(escapeJSONString "${statusText}")

        listItemsJSON="${listItemsJSON}${separator}
        {\"title\":\"${escapedDisplayName}\",\"subtitle\":\"${escapedSubtitle}\",\"icon\":\"${escapedIconURL}\",\"status\":\"${dialogStatus}\",\"statustext\":\"${escapedStatusText}\",\"iconalpha\":1}"
        separator=","
    done

    print -r -- "[
${listItemsJSON}
    ]"
}



####################################################################################################
#
# swiftDialog Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogInstall() {
    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" \
        | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Validate URL was retrieved
    if [[ -z "${dialogURL}" ]]; then
        fatal "Failed to retrieve swiftDialog download URL from GitHub API"
    fi

    # Validate URL format
    if [[ ! "${dialogURL}" =~ ^https://github\.com/ ]]; then
        fatal "Invalid swiftDialog URL format: ${dialogURL}"
    fi

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    preFlight "Installing swiftDialog from ${dialogURL}..."

    # Create temporary working directory
    dialogTemporaryDirectory=$( mktemp -d "/private/tmp/${organizationScriptName}.XXXXXX" )
    if [[ -z "${dialogTemporaryDirectory}" || ! -d "${dialogTemporaryDirectory}" ]]; then
        fatal "Failed to create temporary working directory for swiftDialog installation"
    fi

    # Download the installer package with timeouts
    if ! curl --location --silent --fail --connect-timeout 10 --max-time 60 \
             "$dialogURL" -o "${dialogTemporaryDirectory}/Dialog.pkg"; then
        rm -Rf "${dialogTemporaryDirectory}"
        dialogTemporaryDirectory=""
        fatal "Failed to download swiftDialog package"
    fi

    # Verify the download
    teamID=$(spctl -a -vv -t install "${dialogTemporaryDirectory}/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

        installer -pkg "${dialogTemporaryDirectory}/Dialog.pkg" -target /
        sleep 2
        dialogVersion=$( /usr/local/bin/dialog --version )
        preFlight "swiftDialog version ${dialogVersion} installed; proceeding..."

    else

        # Display a so-called "simple" dialog if Team ID fails to validate
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "'"${humanReadableScriptName}"' Error" buttons {"Close"} with icon caution'
        exit "1"

    fi

    # Remove the temporary working directory when done
    rm -Rf "${dialogTemporaryDirectory}"
    dialogTemporaryDirectory=""

}

function dialogCheck() {

    # Check for Dialog and install if not found
    if [[ ! -d "${dialogAppBundle}" ]]; then

        preFlight "swiftDialog not found; installing …"
        dialogInstall
        if [[ ! -x "${dialogBinary}" ]]; then
            fatal "swiftDialog still not found; are downloads from GitHub blocked on this Mac?"
        fi

    else

        dialogVersion=$("${dialogBinary}" --version)
        if ! is-at-least "${swiftDialogMinimumRequiredVersion}" "${dialogVersion}"; then

            preFlight "swiftDialog version ${dialogVersion} found but swiftDialog ${swiftDialogMinimumRequiredVersion} or newer is required; updating …"
            dialogInstall
            if [[ ! -x "${dialogBinary}" ]]; then
                fatal "Unable to update swiftDialog; are downloads from GitHub blocked on this Mac?"
            fi

        else

            preFlight "swiftDialog version ${dialogVersion} found; proceeding …"

        fi

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Formatted Elapsed Time
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function formattedElapsedTime() {
    /usr/bin/printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {
    exitCode="${1:-0}"
    
    notice "Exiting …"
    
    # Kill dialog process if still running
    if [[ -n "${dialogPID}" ]]; then
        if kill -0 "${dialogPID}" 2>/dev/null; then
            info "Terminating Inspect Mode (PID: ${dialogPID})"
            kill "${dialogPID}" 2>/dev/null || true
            /bin/sleep 1
        fi
    fi
    
    cleanup
    
    info "Total Elapsed Time: $(formattedElapsedTime)"
    info "So long!"
    
    exit "${exitCode}"
}



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    /usr/bin/touch "${scriptLog}"
    if [[ -f "${scriptLog}" ]]; then
        preFlight "Created specified scriptLog: ${scriptLog}"
    else
        fatal "Unable to create specified scriptLog '${scriptLog}'; exiting.\n\n(Is this script running as 'root' ?)"
    fi
fi

# Check and rotate log if exceeds max size
logSize=$(/usr/bin/stat -f%z "${scriptLog}" 2>/dev/null || /bin/echo "0")
maxLogSize=$((10 * 1024 * 1024))  # 10MB

if (( logSize > maxLogSize )); then
    preFlight "Log file exceeds ${maxLogSize} bytes; rotating"
    if /bin/mv "${scriptLog}" "${scriptLog}.$(/bin/date +%s).old" 2>/dev/null; then
        /usr/bin/touch "${scriptLog}"
        preFlight "Log file rotated"
    else
        warning "Unable to rotate log file"
    fi
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# https://snelson.us/sym\n###\n"
preFlight "Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    fatal "This script must be run as root; exiting."
fi

preFlight "Running as root; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Normalize Jamf Policy Item Availability
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

normalizeJamfPolicyItems

if [[ "${enableJamfPolicyItems:l}" == "true" ]]; then
    preFlight "Jamf policy items enabled (${#jamfPolicyItems[@]} configured)"
else
    preFlight "Jamf policy items disabled by configuration"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Logged-in System Accounts (Interactive Mode)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${operationMode}" != "silent" ]]; then
    maxWait=120
    counter=0

    preFlight "Check for Logged-in System Accounts …"
    currentLoggedInUser

    until [[ -n "${loggedInUser}" && "${loggedInUser}" != "loginwindow" ]]; do
        if [[ "${counter}" -ge "${maxWait}" ]]; then
            fatal "No valid user logged in after ${maxWait} seconds; exiting."
        fi
        sleep 1
        ((counter++))
        currentLoggedInUser
        preFlight "Logged-in User Counter: ${counter}"
    done

    if ! /usr/bin/id -u "${loggedInUser}" >/dev/null 2>&1; then
        fatal "Logged-in GUI user '${loggedInUser}' is not resolvable; exiting."
    fi

    updateLoggedInUserDetails
    preFlight "Current Logged-in User First Name (ID): ${loggedInUserFirstname} (${loggedInUserID})"
    preFlight "Validated logged-in GUI user '${loggedInUser}'."
else
    preFlight "Silent mode enabled; skipping logged-in GUI user pre-flight check."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Installomator Labels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

normalizeInstallomatorLabels



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Jamf Binary (if Jamf policy items configured)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${#jamfPolicyItems[@]} -gt 0 ]]; then
    if [[ ! -x "${jamfBinary}" ]]; then
        warning "Jamf binary not found at ${jamfBinary}"
        warning "Jamf policy items will be skipped"
    else
        preFlight "Jamf binary found at ${jamfBinary}"
    fi
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Pre-flight checks complete!"



####################################################################################################
#
# Inspect Mode Configuration Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create swiftDialog Inspect Mode Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function createSYMLiteInspectConfig() {
    local totalItems=${#selectedItems[@]}
    local dialogTitle=""
    local messageText
    local cachePathsJSON
    local sideMessageJSON

    dialogInspectModeJSONFile=$( /usr/bin/mktemp "/var/tmp/dialogJSONFile_InspectMode_${organizationScriptName}.XXXXXX" )
    if [[ -z "${dialogInspectModeJSONFile}" || ! -e "${dialogInspectModeJSONFile}" ]]; then
        fatal "Failed to create Dialog inspect config file"
    fi
    
    # Build items array JSON with guiIndex
    local itemsJSON=""
    local firstItem=true
    local guiIndex=0
    
    for itemID in "${selectedItems[@]}"; do
        local itemType
        itemType=$(getItemType "${itemID}")
        
        local itemConfig
        itemConfig=$(getItemConfig "${itemID}")
        
        if [[ "${itemType}" == "installomator" ]]; then
            parseInstallomatorItem "${itemConfig}"
            local jsonBlock="{
            \"id\": \"${itemLabel}\",
            \"displayName\": \"${itemDisplayName}\",
            \"guiIndex\": ${guiIndex},
            \"paths\": [\"${itemValidationPath}\"],
            \"icon\": \"${itemIconURL}\"
        }"
        elif [[ "${itemType}" == "jamf" ]]; then
            parseJamfPolicyItem "${itemConfig}"
            local jsonBlock="{
            \"id\": \"${itemTrigger}\",
            \"displayName\": \"${itemDisplayName}\",
            \"guiIndex\": ${guiIndex},
            \"paths\": [\"${itemValidationPath}\"],
            \"icon\": \"${itemIconURL}\"
        }"
        else
            warning "Unknown item type for ID: ${itemID}"
            continue
        fi
        
        if [[ "${firstItem}" == "true" ]]; then
            itemsJSON="${jsonBlock}"
            firstItem=false
        else
            itemsJSON="${itemsJSON},
        ${jsonBlock}"
        fi
        
        ((guiIndex++))
    done

    if [[ ${#selectedInstallomatorLabels[@]} -gt 0 && ${#selectedJamfPolicies[@]} -gt 0 ]]; then
        dialogTitle="Processing ${totalItems} Item"
        [[ ${totalItems} -gt 1 ]] && dialogTitle="${dialogTitle}s"
        messageText="Installing selected applications and executing policies. Items complete when files appear at their validation paths."
        cachePathsJSON='        "/Library/Application Support/Installomator/Downloads",
        "/Library/Application Support/JAMF/Downloads",
        "/Library/Managed Installs/Cache"'
        sideMessageJSON='        "Thank you for your patience.",
        "Installation progress is monitored by watching for files to appear.",
        "Applications are being installed via Installomator.",
        "Policies are being executed via Jamf Pro.",
        "Please wait while items are being processed.",
        "Each item completes when its validation path appears.",
        "This process may take several minutes.",
        "The installation will complete automatically.",
        "A restart may be required after completion."'
    elif [[ ${#selectedJamfPolicies[@]} -gt 0 ]]; then
        dialogTitle="Executing ${totalItems} Policy"
        [[ ${totalItems} -gt 1 ]] && dialogTitle="${dialogTitle}ies"
        messageText="Executing selected policies. Items complete when files appear at their validation paths."
        cachePathsJSON='        "/Library/Application Support/JAMF/Downloads",
        "/Library/Managed Installs/Cache"'
        sideMessageJSON='        "Thank you for your patience.",
        "Progress is monitored by watching for files to appear.",
        "Policies are being executed via Jamf Pro.",
        "Please wait while items are being processed.",
        "Each item completes when its validation path appears.",
        "This process may take several minutes.",
        "The installation will complete automatically.",
        "A restart may be required after completion."'
    else
        dialogTitle="Installing ${totalItems} Application"
        [[ ${totalItems} -gt 1 ]] && dialogTitle="${dialogTitle}s"
        messageText="Installing selected applications. Items complete when files appear at their validation paths."
        cachePathsJSON='        "/Library/Application Support/Installomator/Downloads",
        "/Library/Managed Installs/Cache"'
        sideMessageJSON='        "Thank you for your patience.",
        "Installation progress is monitored by watching for files to appear.",
        "Applications are being installed via Installomator.",
        "Please wait while items are being processed.",
        "Each item completes when its validation path appears.",
        "This process may take several minutes.",
        "The installation will complete automatically.",
        "A restart may be required after completion."'
    fi
    
    # Create the full JSON configuration
    # Note: Inspect Mode uses dual monitoring:
    # - logMonitor: Parses Installomator.log for rich status updates (Installomator labels only)
    # - paths: Watches file system via FSEvents for completion detection (both types)
    if ! /bin/cat > "${dialogInspectModeJSONFile}" <<EOF
{
    "preset": "preset${organizationPreset}",
    "title": "${dialogTitle}",
    "message": "${messageText}",
    "icon": "${mainDialogIcon}",
    "overlayicon": "${organizationOverlayiconURL}",
    "iconsize": 120,
    "size": "compact",
    "logMonitor": {
        "path": "${installomatorLog}",
        "preset": "installomator",
        "autoMatch": true,
        "startFromEnd": true
    },
    "cachePaths": [
${cachePathsJSON}
    ],
    "scanInterval": 2,
    "sideMessage": [
${sideMessageJSON}
    ],
    "sideInterval": 8,
    "highlightColor": "#51a3ef",
    "button1text": "Please wait...",
    "button1disabled": true,
    "autoEnableButton": true,
    "autoEnableButtonText": "Review Results",
    "items": [
        ${itemsJSON}
    ]
}
EOF
    then
        fatal "Failed to create Dialog inspect config file"
    else
        info "Dialog inspect config file created at ${dialogInspectModeJSONFile}"
    fi
    
    # Validate JSON with built-in macOS tooling.
    # `plutil -lint` only validates property lists, not raw JSON.
    local jsonValidationError
    jsonValidationError=$(/usr/bin/plutil -convert json -o /dev/null "${dialogInspectModeJSONFile}" 2>&1)
    if [[ $? -ne 0 ]]; then
        fatal "Dialog inspect config JSON is malformed: ${jsonValidationError}"
    else
        info "Dialog inspect config JSON validated successfully"
    fi

    return 0
}

function prepareInspectConfigForUser() {
    if [[ -z "${dialogInspectModeJSONFile}" || ! -e "${dialogInspectModeJSONFile}" ]]; then
        fatal "Dialog inspect config file is unavailable for user handoff."
    fi

    if [[ -z "${loggedInUser}" ]]; then
        fatal "No logged-in user available to receive Dialog inspect config."
    fi

    if ! /usr/sbin/chown "${loggedInUser}" "${dialogInspectModeJSONFile}" 2>/dev/null; then
        fatal "Failed to set ownership on Dialog inspect config for ${loggedInUser}."
    fi

    if ! /bin/chmod 600 "${dialogInspectModeJSONFile}" 2>/dev/null; then
        fatal "Failed to set permissions on Dialog inspect config for ${loggedInUser}."
    fi

    info "Dialog inspect config handed off to ${loggedInUser}."
}

function prepareCompletionDialogConfigForUser() {
    if [[ -z "${completionDialogJSONFile}" || ! -e "${completionDialogJSONFile}" ]]; then
        fatal "Completion dialog config file is unavailable for user handoff."
    fi

    if [[ -z "${loggedInUser}" ]]; then
        fatal "No logged-in user available to receive completion dialog config."
    fi

    if ! /usr/sbin/chown "${loggedInUser}" "${completionDialogJSONFile}" 2>/dev/null; then
        fatal "Failed to set ownership on completion dialog config for ${loggedInUser}."
    fi

    if ! /bin/chmod 600 "${completionDialogJSONFile}" 2>/dev/null; then
        fatal "Failed to set permissions on completion dialog config for ${loggedInUser}."
    fi

    info "Completion dialog config handed off to ${loggedInUser}."
}

####################################################################################################
#
# Selection Interface Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Operations CSV (for silent mode)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseOperationsCSV() {
    local csv="$1"
    selectedItems=()
    [[ -z "${csv}" ]] && return 0

    local oldIFS="$IFS"
    IFS=','
    local itemID
    for itemID in ${csv}; do
        itemID="${itemID// /}"                    # Strip whitespace
        [[ -z "${itemID}" ]] && continue          # Skip empty entries
        
        # Validate item exists
        local itemType
        itemType=$(getItemType "${itemID}")
        if [[ -n "${itemType}" ]]; then
            # Add only if not already present
            if [[ ! " ${selectedItems[@]} " =~ " ${itemID} " ]]; then
                selectedItems+=("${itemID}")
            fi
        else
            if isConfiguredInstallomatorLabel "${itemID}"; then
                warning "Skipping CSV item '${itemID}': Installomator label is unavailable in ${organizationInstallomatorFile}"
            elif [[ "${enableJamfPolicyItems:l}" != "true" ]] && isConfiguredJamfPolicyItem "${itemID}"; then
                warning "Skipping CSV item '${itemID}': Jamf policy items are disabled"
            else
                warning "Unknown item ID in CSV: '${itemID}'"
            fi
        fi
    done
    IFS="${oldIFS}"
    
    info "Parsed CSV: ${#selectedItems[@]} valid items selected"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Dialog Selections (from JSON output)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseDialogSelections() {
    local output="$1"
    selectedItems=()

    if [[ ${#selectionDialogOptionRecords[@]} -gt 0 ]]; then
        local itemID=""

        for itemID in "${selectionDialogOptionRecords[@]}"; do
            if command -v jq >/dev/null 2>&1; then
                if echo "${output}" | jq -e --arg key "${itemID}" '.[$key] == true' >/dev/null 2>&1; then
                    selectedItems+=("${itemID}")
                fi
                continue
            fi

            if echo "${output}" | grep -Fq "\"${itemID}\":true" || echo "${output}" | grep -Fq "\"${itemID}\": true"; then
                selectedItems+=("${itemID}")
            fi
        done

        info "Parsed dialog selections: ${#selectedItems[@]} items selected"
        return 0
    fi

    # Get all possible item IDs
    local allIDs
    allIDs=($(getAllItemIDs))

    # Primary: regex search for pattern like "itemID": true
    local itemID
    for itemID in "${allIDs[@]}"; do
        if echo "${output}" | grep -Eiq "${itemID}\"?[[:space:]]*:[[:space:]]*(true|1|yes)"; then
            selectedItems+=("${itemID}")
        fi
    done

    # Fallback: JSON-aware jq parsing if grep found nothing
    if [[ ${#selectedItems[@]} -eq 0 ]] && command -v jq >/dev/null 2>&1; then
        for itemID in "${allIDs[@]}"; do
            if echo "${output}" | jq -e ".${itemID} == true" >/dev/null 2>&1; then
                selectedItems+=("${itemID}")
            fi
        done
    fi
    
    info "Parsed dialog selections: ${#selectedItems[@]} items selected"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Show No Selectable Items Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function showNoSelectableItemsDialog() {
    requireLoggedInUser "display no selectable items dialog"

    local messageText="There are no selectable items available right now."

    if [[ ${selectionDialogTotalItemCount} -gt 0 ]] \
    && [[ "${selectionDialogStatusSublabelsEnabled:l}" == "true" ]] \
    && [[ ${selectionDialogDisabledItemCount} -eq ${selectionDialogTotalItemCount} ]]; then
        messageText="All configured items are already installed, so there is nothing new to install right now."
    fi

    runAsUser "${loggedInUser}" "${dialogBinary}" \
        --title "${humanReadableScriptName}" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "${messageText}" \
        --icon "${mainDialogIcon}" \
        --button1text "Close" \
        --height 325 \
        --width 500 2>/dev/null

    notice "No selectable items were available in the interactive picker"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Show Selection Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function showSelectionDialog() {
    if [[ "${operationMode}" == "silent" ]]; then
        parseOperationsCSV "${operationsCSV}"
        if [[ ${#selectedItems[@]} -eq 0 ]]; then
            errorOut "Silent mode: no valid operations selected from operationsCSV"
            return 1
        fi
        return 0
    fi

    requireLoggedInUser "display selection dialog"

    local baseMessage
    local warningMessage=""
    local messageText
    local dialogOutput
    local rc

    # Build message
    baseMessage="**$(date +'Happy %A,') ${loggedInUserFirstname}!**\n\nSelect one or more applications to install."

    # Build unified checkbox list (Installomator + Jamf, sorted together by display name)
    getSelectionDialogCheckboxesJSON

    if [[ ${selectionDialogTotalItemCount} -eq 0 ]]; then
        showNoSelectableItemsDialog
        quitScript 0
    fi

    if [[ ${#selectionDialogOptionRecords[@]} -eq 0 ]]; then
        showNoSelectableItemsDialog
        quitScript 0
    fi

    # Loop until at least one item is selected
    while true; do
        messageText="${baseMessage}"
        if [[ -n "${warningMessage}" ]]; then
            messageText="${messageText}\n\n**${warningMessage}**"
        fi

        dialogOutput="$(${dialogBinary} \
            --title "${humanReadableScriptName}" \
            --infotext "${scriptVersion}" \
            --messagefont "size=${fontSize}" \
            --message "${messageText}" \
            --icon "${mainDialogIcon}" \
            --jsonstring "{\"checkbox\":${selectionDialogCheckboxesJSON}}" \
            --checkboxstyle "switch,large" \
            --json \
            --button1text "Install" \
            --button2text "Cancel" \
            --height 675 \
            --width 900 2>/dev/null)"

        rc=$?
        if [[ ${rc} -ne 0 ]]; then
            info "User cancelled selection dialog"
            quitScript 2
        fi

        parseDialogSelections "${dialogOutput}"
        if [[ ${#selectedItems[@]} -gt 0 ]]; then
            notice "User selected ${#selectedItems[@]} items"
            return 0
        fi

        # Warn and retry if no selections
        warning "No items selected in picker; re-showing selection dialog"
        warningMessage="**:red[Warning:]** Please select at least _one_ option before clicking **Install**."
    done
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Separate Selected Items by Type
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function separateSelectedItemsByType() {
    selectedInstallomatorLabels=()
    selectedJamfPolicies=()
    
    for itemID in "${selectedItems[@]}"; do
        local itemType
        itemType=$(getItemType "${itemID}")
        
        if [[ "${itemType}" == "installomator" ]]; then
            selectedInstallomatorLabels+=("${itemID}")
        elif [[ "${itemType}" == "jamf" ]]; then
            selectedJamfPolicies+=("${itemID}")
        fi
    done
    
    info "Separated selections: ${#selectedInstallomatorLabels[@]} Installomator, ${#selectedJamfPolicies[@]} Jamf policies"
}



####################################################################################################
#
# Execution Engine Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Installomator Label
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeInstallomatorLabel() {
    local label="$1"
    local validationPath="$2"
    local displayName="$3"
    local iconURL="$4"
    local installomatorExitCode
    
    # Check if already installed
    if [[ -n "${validationPath}" && -e "${validationPath}" ]]; then
        info "Skipping '${label}': ${validationPath} already exists"
        skippedItems+=("${displayName}")
        addCompletionReportRecord "${displayName}" "alreadyInstalled" "success" "${iconURL}" "No action was needed" "Already installed"
        return 0
    fi
    
    notice "Installing '${label}' (${displayName}) …"
    
    # Execute Installomator
    "${organizationInstallomatorFile}" "${label}" \
        DEBUG=0 NOTIFY=silent 2>&1 | while IFS= read -r installomatorOutputLine; do
            logComment "Installomator (${label}): ${installomatorOutputLine}"
        done
    installomatorExitCode=${pipestatus[1]}

    if [[ ${installomatorExitCode} -ne 0 ]]; then
        errorOut "Installomator failed for '${label}' (exit code: ${installomatorExitCode})"
        failedItems+=("${displayName}")
        addCompletionReportRecord "${displayName}" "notInstalled" "fail" "${iconURL}" "Please contact support if this app is required" "Not installed"
        return 1
    else
        info "Installomator completed for '${label}'"
        completedItems+=("${displayName}")
        addCompletionReportRecord "${displayName}" "installed" "success" "${iconURL}" "Ready to use" "Installed"
        return 0
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Jamf Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeJamfPolicy() {
    local trigger="$1"
    local validationPath="$2"
    local displayName="$3"
    local iconURL="$4"
    local jamfExitCode
    
    # Check if already configured (validation path exists)
    if [[ -n "${validationPath}" && -e "${validationPath}" ]]; then
        info "Skipping policy '${trigger}': ${validationPath} already exists"
        skippedItems+=("${displayName}")
        addCompletionReportRecord "${displayName}" "alreadyInstalled" "success" "${iconURL}" "No action was needed" "Already installed"
        return 0
    fi
    
    notice "Executing Jamf policy '${trigger}' (${displayName}) …"
    
    # Execute Jamf policy and log output
    "${jamfBinary}" policy -event "${trigger}" 2>&1 | while IFS= read -r jamfOutputLine; do
        logComment "Jamf (${trigger}): ${jamfOutputLine}"
    done
    jamfExitCode=${pipestatus[1]}

    # Post-execution validation
    if [[ ${jamfExitCode} -eq 0 ]]; then
        if [[ -n "${validationPath}" && -e "${validationPath}" ]]; then
            info "Jamf policy '${trigger}' completed successfully and validated"
            completedItems+=("${displayName}")
            addCompletionReportRecord "${displayName}" "installed" "success" "${iconURL}" "Ready to use" "Installed"
            return 0
        else
            warning "Jamf policy '${trigger}' completed but validation path not found: ${validationPath}"
            # Still mark as completed since jamf returned 0
            completedItems+=("${displayName}")
            addCompletionReportRecord "${displayName}" "needsReview" "error" "${iconURL}" "Installed, but we could not fully confirm the result" "Needs review"
            return 0
        fi
    else
        errorOut "Jamf policy '${trigger}' failed (exit code: ${jamfExitCode})"
        failedItems+=("${displayName}")
        addCompletionReportRecord "${displayName}" "notInstalled" "fail" "${iconURL}" "Please contact support if this app is required" "Not installed"
        return 1
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Unified Execution Dispatcher
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeSYMLiteItems() {
    notice "Starting execution of ${#selectedItems[@]} selected items"
    completionReportRecords=()

    if [[ ${#selectedItems[@]} -eq 0 ]]; then
        errorOut "No selected items available for execution"
        return 1
    fi
    
    if [[ "${operationMode}" != "silent" ]]; then
        requireLoggedInUser "launch Inspect Mode"

        # Create Inspect Mode configuration
        notice "Creating Inspect Mode configuration …"
        if ! createSYMLiteInspectConfig; then
            fatal "Failed to create Inspect Mode configuration"
        fi

        prepareInspectConfigForUser

        # Launch Dialog in background for real-time progress
        notice "Launching Inspect Mode dialog …"
        runAsUser "${loggedInUser}" /usr/bin/env DIALOG_INSPECT_CONFIG="${dialogInspectModeJSONFile}" "${dialogBinary}" --inspect-mode &
        dialogPID=$!
        info "Inspect Mode PID: ${dialogPID}"

        # Give dialog a moment to launch
        sleep 2
    else
        info "Silent mode enabled; skipping Inspect Mode UI"
    fi
    
    # Process each selected item sequentially
    for itemID in "${selectedItems[@]}"; do
        local itemType
        itemType=$(getItemType "${itemID}")
        
        local itemConfig
        itemConfig=$(getItemConfig "${itemID}")
        
        if [[ "${itemType}" == "installomator" ]]; then
            parseInstallomatorItem "${itemConfig}"
            executeInstallomatorLabel "${itemLabel}" "${itemValidationPath}" "${itemDisplayName}" "${itemIconURL}"
        elif [[ "${itemType}" == "jamf" ]]; then
            parseJamfPolicyItem "${itemConfig}"
            executeJamfPolicy "${itemTrigger}" "${itemValidationPath}" "${itemDisplayName}" "${itemIconURL}"
        else
            warning "Unknown item type for ID: ${itemID}"
        fi
    done
    
    if [[ -n "${dialogPID}" ]]; then
        # Wait for Dialog to close (with timeout)
        info "Waiting for Inspect Mode (PID: ${dialogPID}) to close …"
        local waitCount=0
        local maxWait=30
        while kill -0 "${dialogPID}" 2>/dev/null && (( waitCount < maxWait )); do
            sleep 1
            ((waitCount++))
        done

        if kill -0 "${dialogPID}" 2>/dev/null; then
            warning "Dialog did not close after ${maxWait} seconds; terminating"
            kill "${dialogPID}" 2>/dev/null || true
            sleep 1
        fi

        info "Inspect Mode closed."
    fi
    
    notice "Execution complete: ${#completedItems[@]} completed, ${#skippedItems[@]} skipped, ${#failedItems[@]} failed"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Interruption Handler
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function handleInterruption() {
    warning "Script interrupted by user"
    
    # Kill dialog if still running
    if [[ -n "${dialogPID}" ]]; then
        if kill -0 "${dialogPID}" 2>/dev/null; then
            info "Terminating Inspect Mode (PID: ${dialogPID})"
            kill "${dialogPID}" 2>/dev/null || true
        fi
    fi
    
    cleanup
    exit 130
}

trap handleInterruption SIGINT SIGTERM



####################################################################################################
#
# Completion and Restart Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Completion Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function showCompletionDialog() {
    requireLoggedInUser "display completion dialog"

    local installedCount=0
    local alreadyInstalledCount=0
    local needsReviewCount=0
    local notInstalledCount=0
    local record=""
    local displayName=""
    local statusKey=""
    local dialogStatus=""
    local iconURL=""
    local subtitle=""
    local statusText=""
    local dialogTitle=""
    local dialogIcon=""
    local dialogMessage="Here's the status of your selected software, ${loggedInUserFirstname}.\n\n"
    local listItemsJSON=""
    local completionDialogJSON=""
    local jsonValidationError=""
    local retryCount=0
    local maxRetries=5

    for record in "${completionReportRecords[@]}"; do
        IFS=$'\t' read -r displayName statusKey dialogStatus iconURL subtitle statusText <<< "${record}"

        case "${statusKey}" in
            installed )
                ((installedCount++))
                ;;
            alreadyInstalled )
                ((alreadyInstalledCount++))
                ;;
            needsReview )
                ((needsReviewCount++))
                ;;
            notInstalled )
                ((notInstalledCount++))
                ;;
        esac
    done

    if [[ ${notInstalledCount} -gt 0 ]]; then
        dialogTitle="Completed with Errors"
        dialogIcon="SF=xmark.octagon.fill,weight=bold,colour1=#EB5545,colour2=#A61E16"
    elif [[ ${needsReviewCount} -gt 0 ]]; then
        dialogTitle="Completed with Warnings"
        dialogIcon="SF=exclamationmark.triangle.fill,weight=bold,colour1=#F8D84A,colour2=#D18E00"
    else
        dialogTitle="Installation Complete"
        dialogIcon="SF=checkmark.circle.fill,weight=bold,colour1=#63CA56,colour2=#2D7D2B"
    fi

    [[ ${installedCount} -gt 0 ]] && dialogMessage="${dialogMessage}**${installedCount}** installed and ready to use.\n"
    [[ ${alreadyInstalledCount} -gt 0 ]] && dialogMessage="${dialogMessage}**${alreadyInstalledCount}** already installed.\n"
    [[ ${needsReviewCount} -gt 0 ]] && dialogMessage="${dialogMessage}**${needsReviewCount}** need review.\n"
    [[ ${notInstalledCount} -gt 0 ]] && dialogMessage="${dialogMessage}**${notInstalledCount}** not installed.\n"

    listItemsJSON=$(buildCompletionReportListItemsJSON)

    completionDialogJSONFile="$(mktemp "/var/tmp/dialogJSONFile_Completion_${organizationScriptName}.XXXXXX")"
    if [[ -z "${completionDialogJSONFile}" ]]; then
        fatal "Failed to create completion dialog JSON file"
    fi

    completionDialogJSON="{
    \"title\": \"$(escapeJSONString "${dialogTitle}")\",
    \"message\": \"$(escapeJSONString "${dialogMessage}")\",
    \"icon\": \"$(escapeJSONString "${dialogIcon}")\",
    \"button1text\": \"Close\",
    \"infotext\": \"$(escapeJSONString "${scriptVersion}")\",
    \"height\": 675,
    \"width\": 900,
    \"messagefont\": \"size=${fontSize}\",
    \"listitem\": ${listItemsJSON}
}"

    if ! /bin/cat > "${completionDialogJSONFile}" <<EOF
${completionDialogJSON}
EOF
    then
        rm -f -- "${completionDialogJSONFile}" 2>/dev/null
        completionDialogJSONFile=""
        fatal "Failed to write completion dialog JSON file"
    fi

    jsonValidationError=$(/usr/bin/plutil -convert json -o /dev/null "${completionDialogJSONFile}" 2>&1)
    if [[ $? -ne 0 ]]; then
        rm -f -- "${completionDialogJSONFile}" 2>/dev/null
        completionDialogJSONFile=""
        fatal "Completion dialog JSON is malformed: ${jsonValidationError}"
    fi

    prepareCompletionDialogConfigForUser

    while [[ ! -f "${completionDialogJSONFile}" || ! -r "${completionDialogJSONFile}" ]] && [[ ${retryCount} -lt ${maxRetries} ]]; do
        sleep 0.2
        ((retryCount++))
    done

    if [[ ! -f "${completionDialogJSONFile}" || ! -r "${completionDialogJSONFile}" ]]; then
        local unreadableCompletionDialogJSONFile="${completionDialogJSONFile}"
        rm -f -- "${completionDialogJSONFile}" 2>/dev/null
        completionDialogJSONFile=""
        fatal "Completion dialog JSON file (${unreadableCompletionDialogJSONFile}) is not readable after ${maxRetries} attempts"
    fi

    runAsUser "${loggedInUser}" "${dialogBinary}" --jsonfile "${completionDialogJSONFile}" 2>/dev/null

    rm -f -- "${completionDialogJSONFile}" 2>/dev/null
    completionDialogJSONFile=""

    notice "Completion dialog closed"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Restart Helpers
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeRestartAction() {
    local effectiveRestartMode="${1:-${restartMode}}"
    local restartCommand=""

    case "${effectiveRestartMode}" in
        Restart)
            restartCommand="sleep 1 && shutdown -r now &"
            if /bin/zsh -c "${restartCommand}" >>"${scriptLog}" 2>&1; then
                notice "Restart command '${effectiveRestartMode}' sent as root: ${restartCommand}"
                return 0
            fi
            warning "Failed to invoke restart command '${effectiveRestartMode}' as root: ${restartCommand}"
            return 1
            ;;
        "Restart Confirm"|*)
            requireLoggedInUser "send restart command"
            if runAsUser "${loggedInUser}" /usr/bin/osascript -e 'tell app "loginwindow" to «event aevtrrst»' >>"${scriptLog}" 2>&1; then
                notice "Restart command '${effectiveRestartMode}' sent for ${loggedInUser}."
                return 0
            fi
            warning "Failed to invoke restart command '${effectiveRestartMode}' for ${loggedInUser}."
            return 1
            ;;
    esac
}

function promptForRestart() {
    if [[ "${restartPromptEnabled}" != "true" ]] || [[ "${operationMode}" == "silent" ]]; then
        return 0
    fi

    requireLoggedInUser "display restart prompt"
    
    local rc
    local restartFontSize=$(( fontSize > 2 ? fontSize - 2 : fontSize ))
    
    ${dialogBinary} \
        --title "Restart Recommended" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${restartFontSize}" \
        --message "**A restart is recommended after performing any installation.**\n\nWould you like to restart now?" \
        --icon "SF=restart.circle.fill,colour=#969899" \
        --buttonstyle "stack" \
        --button1text "Restart Now" \
        --button2text "Later" \
        --height 400 \
        --width 400 2>/dev/null
    
    rc=$?
    
    if [[ ${rc} -eq 0 ]]; then
        notice "User chose to restart now"
        executeRestartAction "Restart Confirm"
    else
        notice "User chose to restart later"
    fi
}



####################################################################################################
#
# Main Program
#
####################################################################################################

notice "SYM-Lite initialized successfully"
notice "Configuration: ${#installomatorLabels[@]} Installomator labels, ${#jamfPolicyItems[@]} Jamf policy items"
if [[ "${enableJamfPolicyItems:l}" != "true" ]]; then
    notice "Jamf policy items are disabled by configuration"
fi
notice "Operation mode: ${operationMode}"

# Phase 2: Show selection dialog
if ! showSelectionDialog; then
    fatal "No valid operations were selected; exiting."
fi
separateSelectedItemsByType

# Phase 3 & 4: Execute selected items via Inspect Mode
if ! executeSYMLiteItems; then
    fatal "Failed to execute selected items"
fi

# Phase 5: Display completion and prompt for restart
if [[ "${operationMode}" == "silent" ]]; then
    info "Silent mode enabled; skipping completion dialog and restart prompt"
else
    if [[ ${#completedItems[@]} -eq 0 && ${#failedItems[@]} -eq 0 ]]; then
        notice "All ${#skippedItems[@]} selected items were already installed; showing completion report without restart prompt"
    fi

    showCompletionDialog

    if [[ ${#completedItems[@]} -eq 0 && ${#failedItems[@]} -eq 0 ]]; then
        info "Skipping restart prompt because all selected items were already installed"
    else
        promptForRestart
    fi
fi

info "SYM-Lite execution complete - Total Elapsed Time: $(formattedElapsedTime)"
quitScript 0
