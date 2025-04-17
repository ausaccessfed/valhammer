const common = {
    "extends": [
        "github>ausaccessfed/workflows//.github/renovate-config.json"
    ],
    "username": "aaf-terraform",
    "gitAuthor": "aaf-terraform <fishwhack9000+terraform@gmail.com>",
    "onboarding": false,
    "requireConfig": "optional",
    "automerge": false,
    "ignoreTests": false,
    "platform": "github",
    "forkProcessing": "disabled",
    "labels": [
        "dependencies"
    ],
    "lockFileMaintenance": {
        "enabled": false
    },
    "ignorePaths": [
        "**/node_modules/**",
        "**/bower_components/**",
        "**/vendor/**",
        "**/examples/**",
        "**/__tests__/**",
        "**/tests/**",
        "**/__fixtures__/**",
        "**/.terraform/**"
    ],
}
//EOF_DISTRIBUTION
module.exports = {
