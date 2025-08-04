# Repository Settings
# This file contains recommended settings for the GitHub repository

# Branch Protection Rules
# Apply these manually in GitHub Settings > Branches

main_branch_protection:
  required_status_checks:
    strict: true
    contexts:
      - "📊 Static Analysis"
      - "🧪 Unit Tests"
      - "🏗️ Build Example"
      - "✅ CI Success"
  enforce_admins: false
  required_pull_request_reviews:
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_approving_review_count: 1
  restrictions: null
  allow_force_pushes: false
  allow_deletions: false

# Repository Settings
repository_settings:
  # General
  description: "Flutter plugin for commercial weight scales via RS232 AUTO COMMUNICATE PROTOCOL"
  homepage_url: "https://pub.dev/packages/weight_scale"
  topics:
    - flutter
    - dart
    - weight-scale
    - rs232
    - usb-serial
    - android
    - commercial-scales
    - protocol
    - hardware-integration
    - iot

# Features

features:
wiki: false
issues: true
projects: true
security_and_analysis: true

# Pull Requests

pull_requests:
allow_merge_commit: true
allow_squash_merge: true
allow_rebase_merge: false
always_suggest_updating_pull_request_branches: true
delete_branch_on_merge: true

# Security

security:
enable_automated_security_fixes: true
enable_vulnerability_alerts: true

# Labels Configuration

# Import these labels for better issue management

labels:

# Type labels

- name: "bug"
  color: "d73a4a"
  description: "Something isn't working"
- name: "enhancement"
  color: "a2eeef"
  description: "New feature or request"
- name: "documentation"
  color: "0075ca"
  description: "Improvements or additions to documentation"
- name: "question"
  color: "d876e3"
  description: "Further information is requested"
- name: "device-support"
  color: "fbca04"
  description: "Adding support for new scale device"

# Priority labels

- name: "priority-low"
  color: "e4e669"
  description: "Low priority issue"
- name: "priority-medium"
  color: "fbca04"
  description: "Medium priority issue"
- name: "priority-high"
  color: "d93f0b"
  description: "High priority issue"
- name: "priority-critical"
  color: "b60205"
  description: "Critical priority issue"

# Status labels

- name: "needs-triage"
  color: "ededed"
  description: "Needs initial review and categorization"
- name: "needs-investigation"
  color: "1d76db"
  description: "Requires further investigation"
- name: "needs-testing"
  color: "7057ff"
  description: "Needs testing with physical device"
- name: "good-first-issue"
  color: "7057ff"
  description: "Good for newcomers"
- name: "help-wanted"
  color: "008672"
  description: "Extra attention is needed"

# Platform labels

- name: "platform-android"
  color: "3ddc84"
  description: "Android platform specific"
- name: "platform-ios"
  color: "007aff"
  description: "iOS platform (future)"

# Component labels

- name: "protocol"
  color: "f9d0c4"
  description: "Related to RS232 protocol parsing"
- name: "connection"
  color: "c2e0c6"
  description: "Device connection and management"
- name: "performance"
  color: "d4c5f9"
  description: "Performance related"
- name: "testing"
  color: "0e8a16"
  description: "Related to testing"

# Automation labels

- name: "automated"
  color: "ededed"
  description: "Created by automation"
- name: "dependencies"
  color: "0366d6"
  description: "Pull requests that update a dependency file"
- name: "github-actions"
  color: "000000"
  description: "Related to GitHub Actions"
- name: "stale"
  color: "fef2c0"
  description: "This issue/PR has been marked as stale"
- name: "monthly-report"
  color: "b4a7d6"
  description: "Monthly community report"
- name: "community"
  color: "0e8a16"
  description: "Community related"

# Issue Templates Configuration

issue_templates:
bug_report: "Use for reporting bugs and issues"
feature_request: "Use for suggesting new features"
device_support: "Use for requesting support for new scale models"
question: "Use for asking questions about usage"

# Recommended Secrets for CI/CD

secrets:
CODECOV_TOKEN: "Token for Codecov integration (optional)"
PUB_CREDENTIALS: "Credentials for pub.dev publishing (for releases)"

# Recommended GitHub Apps/Integrations

recommended_apps:

- name: "Codecov"
  description: "Code coverage reporting"
  url: "https://github.com/apps/codecov"
- name: "Dependabot"
  description: "Automated dependency updates"
  note: "Already configured in .github/dependabot.yml"

# Branch Protection Setup Instructions

setup_instructions: |

1. Go to Settings > Branches
2. Add rule for main branch
3. Enable "Require status checks to pass before merging"
4. Select required status checks:
   - 📊 Static Analysis
   - 🧪 Unit Tests
   - 🏗️ Build Example
   - ✅ CI Success
5. Enable "Require pull request reviews before merging"
6. Set required reviewers to 1
7. Enable "Dismiss stale pull request approvals when new commits are pushed"
