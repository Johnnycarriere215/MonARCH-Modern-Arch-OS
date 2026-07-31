# Theme templates

One file per application. `monarch theme apply` renders every file in this
directory and writes it wherever the file says to. **Adding an application to
the theme system is adding a file here — there is no list to register it in and
no code to change.**

## The header

Lines beginning with `#!` are metadata. They are stripped before the file is
written, which is why the mechanism works identically in a `.css`, a `.toml`
and a `.json`, none of which share a comment character.

```
#!monarch-template
#!target: monarch/theme/hypr-colors.conf
#!reload: hyprctl reload
```

| field | meaning |
|---|---|
| `target:` | Where the rendered file goes. A bare path is relative to `~/.config`; a leading `~/` escapes it. Parent directories are created. Required. |
| `reload:` | Shell command run once after all files are written. Skipped silently if the command is not installed. Optional, may appear more than once. |

Two templates may share a `reload:`; it runs once.

## Substitution

`{{section.key}}`, where the keys are the ones documented in
`schema/theme.toml`. A filter after `|` picks the syntax the app speaks:

| written | renders |
|---|---|
| `{{ui.accent}}` | `#7c6df2` |
| `{{ui.accent\|raw}}` | `7c6df2` |
| `{{ui.accent\|rgb}}` | `rgb(7c6df2)` |
| `{{ui.accent\|rgba:ee}}` | `rgba(7c6df2ee)` |
| `{{ui.accent\|hexa:cc}}` | `#7c6df2cc` |
| `{{ui.accent\|css:0.85}}` | `rgba(124, 109, 242, 0.85)` |
| `{{meta.name}}` | `midnight` — non-colours pass through, filters are an error |

An unknown key or filter aborts the whole apply. A theme that renders half its
colours is worse than one that refuses.

## What to reach for

Prefer `sem.*` over `term.*` when the colour carries meaning — a module
reporting a failing disk wants `sem.urgent`, so that a theme is free to make
"urgent" orange. Use `term.*` only for the terminal itself.
