# Security

Invert Mouse Only is a local, single-purpose utility. It reads your scroll-wheel
events and, when enabled, negates the ones that came from a wheel mouse. It does
**no networking, no analytics, and no file I/O** beyond its own preferences
(`UserDefaults`). That keeps the attack surface small.

## Reporting

If you find a bug, a crash, or anything that looks like a security concern:

1. Prefer opening a **private security advisory** under the repo's
   Settings → Security (visible only to maintainers), or
2. Email harrisanggara@gmail.com.

There is no bug bounty — but genuine issues are taken seriously and fixed.
Given the tiny attack surface, most findings will be plain bugs, and those are
welcome as regular issues too.
