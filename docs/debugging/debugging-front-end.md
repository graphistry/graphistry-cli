# Troubleshooting Front-end issues

These steps show how to capture JavaScript Console Logs, Network Logs & Iframe URLs

### Step 1: Open Chrome Developer Tools

1. Open the webapp in Chrome and reproduce the issue
2. Right-click ➜ Inspect
   Or Ctrl+Shift+I (Windows/Linux) / Cmd+Option+I (Mac)


### Step 2: Capture JavaScript Console Logs

1. In the DevTools panel, go to the Console tab
2. This shows JavaScript errors, warnings, and custom console.log() statements.
3. To Save Console Logs:

	- Right-click in the Console
	- Click "Save as..."
	- Save the .log file (or copy-paste logs into a .txt)

![image](https://github.com/user-attachments/assets/f7f5d9a5-b324-438d-aca3-d56792a89d71)

### Step 3: Capture Network Logs

1. Go to the Network tab
2. Check the box: Preserve log (top-left)
3. Reload the page so all requests (including iframe loads) are captured
4. In the filter/search bar, type: graph.html
5. *Click on the matching request for your issue*
6. You’ll now see detailed tabs:
   - Headers: View full Request and Response headers
   - Preview/Response: See content
7. To export:
   - Click on the down arrow in the menu bar near the top -> Export Har file and save it to disk to send later
   - Or copy headers manually from the Headers tab if only one request matters

![Screenshot 2025-07-02 115822](https://github.com/user-attachments/assets/25e22894-893f-4d67-9380-dd0526836489)

### Step 4: Get the iframe's full URL 

1. Go to Elements tab
2. Press Ctrl + F and search for: iframe
3. Find the iframe element that loads graph.html
4. Check the src attribute — this is the full URL

### Example:

```
<iframe src="https://example.com/path/to/graph.html"></iframe>
```
![image](https://github.com/user-attachments/assets/2a9efc29-297e-4fa1-aef1-15c893298607)

Right-click ➜ Copy link address

Send back this link address to Graphistry Support Team so we can see:  `protocol` + `domain` + `subpath`

### Step 5: Capture Parent Frame URL (Page Origin)

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
![image](https://github.com/user-attachments/assets/fdba0477-c566-444b-bdc6-f33325b520cf)


Also run:

```
window.location.origin
```

![image](https://github.com/user-attachments/assets/29ef1142-169c-44bf-bf2d-2a4914e6f6e4)

To confirm just protocol + domain (e.g., https://myapp.domain.com)

### Step 6: Send the following back to the Graphistry Support Staff: 

| Item                                    | Where to Get                      |
| --------------------------------------- | --------------------------------- |
| Full iframe URL                         | From Elements tab or Console      |
| Request + Response Headers for iframe   | From Network tab: `graph.html`    |
| Full Parent Page URL                    | `window.location.href` in Console |
| HAR file                                | From Network tab                  |
| Console logs                            | From Console tab                  |

