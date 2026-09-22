# Release Title Rules

## Purpose

Keep release pages consistent and easy to identify.

## Required title format

Every GitHub release title **must be exactly the version tag**.

```text
Release title = tag name
```

### Examples

| Tag | Release title |
|---|---|
| `v0.47.64` | `v0.47.64` |
| `v0.46.62` | `v0.46.62` |
| `v0.29.55` | `v0.29.55` |

## Do not add

Release titles must not include:

- The project name, such as `ULS`
- A release summary or feature description
- Emojis
- Text added by an agent
- Extra spaces or punctuation

Use the release notes field for summaries, changes, fixes, and other details.

## Team checklist

Before publishing a release, confirm that:

- [ ] The tag uses the version format, such as `v1.2.3`.
- [ ] The release title exactly matches the tag.
- [ ] The release notes contain the changes and fixes.
- [ ] No additional words appear in the title.

## Command example

```bash
gh release create "v<VERSION>" \
  --repo Jaseunda/uls \
  --title "v<VERSION>" \
  --generate-notes
```
