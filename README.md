# TMUX Focus Pane ☸️

Zoom and center a pane to a new window, and reset pane to original location when
navigating away.

![Example screenshot of focus pane](/images/focus-pane.png)

## Installation

### Requirements

* tmux version `3.2` or higher. This is required to support the latest hook
  syntax
* Perl version `5.010` or higher

### Using TPM

Add the plugin to the list of TPM plugins:

```
set -g @plugin 'rahulkjoshi/tmux-focus-pane'
```
Then install the new plugin with `prefix + I`.

## Usage

### Toggle Focus Mode

Use the `@tmux-focus-toggle` binding (default `prefix + z`) to toggle zooming a
particular pane. If a pane is already zoomed in, the same binding returns it to
its original position.

### Pane/Window Change Hooks

> TODO

### Zoom Tag (Auto zoom)

> [!Note]
> Requires enabling hooks

> TODO

### Resize Hooks

> TODO

### Configuration Options

| Option                             |  Default Value | Description                                                            |
| ---------------------------------- | -------------: | ---------------------------------------------------------------------- |
| `@tmux-focus-install-hooks`        |        `false` | If `true`, the plugin installs the pane/window change hooks on startup |
| `@tmux-focus-install-resize-hooks` |        `false` | If `true`, the pluging installs the resize hooks on startup            |
| `@tmux-focus-toggle`               |   `prefix + z` | Key-binding to trigger the focus toggle                                |
| `@tmux-focus-zoom-tag`             |   `prefix + Z` | Key-binding to tag a pane to be auto-zoomed                            |
| `@tmux-focus-command-invoke`       | `prefix + M-f` | Key-binding to start a prompt to invoke behaviors manually             |


### Pane Sizing
| Options                         | Default Value | Description                                                                               |
| ------------------------------- | ------------: | ----------------------------------------------------------------------------------------- |
| `@tmux-focus-horizontal-aspect` |           `3` | The horizontal aspect ratio for the focus pane                                            |
| `@tmux-focus-vertical-aspect`   |           `4` | The vertical aspect ratio for the focus pane                                              |
| `@tmux-focus-horizontal-pad`    |           `0` | The padding to add left and right of the focus pane (as a percentage of the window width) |
| `@tmux-focus-vertical-pad`      |           `0` | The padding to add above and below the focus pane (as a percentage of the window height)  |
| `@tmux-focus-horizontal-min`    |         `110` | The minimum width of the focus pane (in characters)                                       |
| `@tmux-focus-horizontal-max`    |         `250` | The maximum width of the focus pane (in characters)                                       |
| `@tmux-focus-vertical-min`      |          `40` | The minimum height of the focus pane (in characters)                                      |
| `@tmux-focus-vertical-max`      |         `100` | The maximum height of the focus pane (in characters)                                      |
