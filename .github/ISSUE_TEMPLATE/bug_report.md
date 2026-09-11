---
name: Bug report
about: Something isn't working as expected
title: ''
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what's wrong.

**Expected behavior**
What did you expect to happen?

**Environment**
- macOS version (e.g. Sequoia 15.1):
- Mac chip (Apple Silicon / Intel):
- Mouse model (and whether it has its own driver software):
- App version (from `About` if present, or how you installed it):

**To reproduce**
Steps:

1. ...

**Debug output**
Run the app with debugging and paste the relevant lines:

```sh
IMO_DEBUG=1 /Applications/invertMouseOnly.app/Contents/MacOS/invertMouseOnly
```

Does the debug log show `continuous=true` for your mouse when it should be
`false`? That tells us whether this is an event-classification issue.
