# Troubleshooting Front-end issues

These steps show how to capture JavaScript Console Logs, Network Logs & Iframe URLs

### Step 1: Open Chrome Developer Tools

1. Open the webapp in Chrome and reproduce the issue
2. Right-click ➜ Inspect
   Or Ctrl+Shift+I (Windows/Linux) / Cmd+Option+I (Mac)


### Step 2: Capture JavaScript Console Logs

1. Go to the Network tab
2. Check the box: Preserve log (top-left)
3. Reload the page so all requests (including iframe loads) are captured
4. In the filter/search bar, type: graph.html
5. Click on the matching request
6. You’ll now see detailed tabs:
   - Headers: View full Request and Response headers
   - Preview/Response: See content
7. To export:
   - Right-click ➜ Save all as HAR with content
   - Or copy headers manually from the Headers tab if only one request mattersStep 3: Capture Network Logs


### Step 3: Get the iframe's full URL (with https/http and path)

1. Go to Elements tab
2. Press Ctrl + F and search for: iframe
3. Find the iframe element that loads graph.html
4. Check the src attribute — this is the full URL

### Example:

```
<iframe src="https://example.com/path/to/graph.html"></iframe>
```

Right-click ➜ Copy → Copy link address

Send back this link address so we can see:  `protocol` + `domain` + `subpath`

### Step 4: Capture Parent Frame URL (Page Origin)

While still in DevTools:

1. Go to the Console tab

2. Type and run:

```
window.location.href
```

This gives the parent frame's full URL — e.g.,

```
https://myserver.domain.com/path
```

Also run:

```
window.location.origin
```

To confirm just protocol + domain (e.g., https://myapp.domain.com)


Please send the following back to the Support Staff: 

| Item                                    | Where to Get                      |
| --------------------------------------- | --------------------------------- |
| Full iframe URL                         | From Elements tab or Console      |
| Request + Response Headers for iframe   | From Network tab: `graph.html`    |
| Full Parent Page URL                    | `window.location.href` in Console |
| HAR file                                | From Network tab                  |
| Console logs                            | From Console tab                  |

