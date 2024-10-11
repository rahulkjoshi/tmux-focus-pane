# TMUX Focus Pane ☸️

Zoom and center a pane to a new window, and reset pane to original location when navigating away.

## Installation

### Requirements

* tmux version `3.2` or higher. This is required to support the latest hook syntax
* Perl version `5.010` or higher

### Using TPM

Add the plugin to the list of TPM plugins:

```
set -g @plugin 'rahulkjoshi/tmux-focus-pane'
```
Then install the new plugin with `prefix + I`

## Usage

### Toggle Focus Mode

Use the `@tmux-focus-toggle` binding (default `prefix + z`) to toggle zooming a particular pane. If a pane is already zoomed in, the same binding returns it to its original position

### Pane Change hooks

> TODO

### Zoom Tag (Auto zoom)

> [!NOTE] Requires enabling hooks

> TODO

### Configuration Options

| Option                       | Default Value  | Description                                                |
| ---------------------------- | -------------- | ---------------------------------------------------------- |
| `@tmux-focus-install-hooks`  | `false`        | If `true`, the plugin installs the hooks on startup        |
| `@tmux-focus-toggle`         | `prefix + z`   | Key-binding to trigger the focus toggle                    |
| `@tmux-focus-zoom-tag`       | `prefix + Z`   | Key-binding to tag a pane to be auto-zoomed                |
| `@tmux-focus-command-invoke` | `prefix + M-f` | Key-binding to start a prompt to invoke behaviors manually |
