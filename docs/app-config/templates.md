# Investigation Templates

Investigation templates bring a lightweight form of automation to investigations. They work just like regular investigations, except they add a few key features that, combined with existing investigation features, unlock useful workflows.

For even friendlier templates that analysts are more comfortable tweaking, consider replacing individual pivots [custom pivots](configure-custom-pivots.md). 

**Contents**
1. Sample workflows
1. Create a template
1. Manual: Instantiate a template
1. URL API: Linking a template
1. Splunk integration
1. Best practices
    * Manual data for first step
    * Multiple entry points
    * Set time range  and provide instructions
    * Naming
    * Cross-linking


## 1. Sample workflows

* **In-tool**: Create a base template such as for looking at an account, and instantiate whenever you are investigating a new account
* **From an alert email or dashboard**: Include a link to a 360 view for that alert or involved entities, and center it on the time range of the incident
* **Splunk UI**: Teach Splunk to include 360 views whenever it mentions an account, IP, or alert


## 2. Create a template

Any investigation can be reused as a template. From an investigation (or `save-a-copy` of one), in the investigation details, check `Template`. When you save and return to the content home, it should have moved into the top `Templates` section. 

## 3. Manual: Instantiate a template

From the content home, navigate to your template, and press the `new` button. This will create a new investigation that is based off of the most recent version of the template, similar to how `clone` works on an investigation. Editing a template keeps past investigations safe and untouched.

## 4. URL API: Linking a template

The magic happens when the URI API is used to enable users of web applications to jump into prebuilt investigations with just one click. 

Consider the following URL for triggering a phone history check:

`/pivot/template?investigation=453d190914cf9fa0&pivot[0][events][0][phone]=1.800.555.5555&time=1504401120.000&before=-1d&after=+1d&name=Phone-History-555-5555`

This URL: Instantiates template `453d190914cf9fa0`, names it `Phone-History-555-5555`, overrides the global time range to center at `1504401120` (epoch time) and runs searches +/- 1 day from then. The first pivot will be populated with one record, and that record will have field `phone` mapped to the string `"1.800.555.5555"`. 


|  FIELD	        | OPTIONAL 	| DEFAULT 	                | FORMAT 	| NOTES 	|
|--------------------:|-------	  |-------	                  |--------	|-------	|
| **investigation** 	| required 	|   	                      | ID 	    | Get template ID from its URL. Ex: 453d190914cf9fa0 	|
| **name** 	          | optional 	| "Copy of [template name]" | String 	| Recommend using a short standard pattern to  group together ("[Phone History] ...") 	|
| **time**	          | optional 	|  now	                    | Number or string 	| Epoch time (number) or best-effort if not a number. Ex: 1504401120 	|
| **before** 	        | optional 	| -7d	                    	| [+/-][number][ms/s/min/h/d/w/mon/y] 	| Ex: -1d 	|
| **after** 	        | optional 	| +0d	                     	| [+/-][number][ms/s/min/h/d/w/mon/y] 	| Ex: +3min 	|
| **pivot** 	        | optional 	|   	                     	|  see below	| see below	|

URL parameter `pivot` follows one of the two following formats:
* `[step][field]`, e.g., `pivot[0][index]=index%3Dalerts`, the URI-encoded form of string `"index=alerts"`
* `[step][field][list_index][record_field]`, e.g., `pivot[0][events][0][phone]=1-800-555-5555` sets the first step's events to JSON list `[ {"phone": "1-800-555-5555"} ]`

You can therefore set or override most investigation step values, not just the first one. Likewise, if you want to trigger an investigation over multiple values, you can provide a list of them.

## 5. Splunk integration

Splunk users can easily jump into Graphistry investigations without much thinking from any Splunk search result or dashboard, even if they don't know which ones are available ahead of time.  To do so, you simply register Graphistry templates as Splunk workflow actions.

To make a template appear as a Workflow Action on a specific kind of event:

1. Settings -> Event Types -> new: 

    * Search string: The events you want the template to appear on (if you don't hav event types already known). Ex: "index=calls phone=*".
    * Tag(s): An identifier to associate with these events

2. Settings -> Fields -> Workflow actions -> new

    * Label: What appears in Splunk's action menu. Ex: `Check Graphistry for Phone 360: $phone$`
    * Apply only to fields, tags: the search result column and/or tag from Step 1
    * Show action in: Both
    * Action type: Link
    * Link configuration: Template URL, using `$fld$` to populate values. Ex: `https://my_graphistry.com/pivot/template?investigation=453d190914cf9fa0&pivot[0][events][0][phone]=$phone$&pivot[0][events][0][time]=$time_epoch$` 
    * Open link in: New window
    * Link method: get

## 6. Best practices

### Manual data for first step

By making the first step an `Enter data` one, most of the parameters can be set on it. The URL generates an initial graph, and subsequent steps expand on them.

### Multiple entry points

You can likely combine multiple templates into one. For example, in IT scenarios, 360 views for IP's, MAC addresses, and host names likely look the same. Make the first step create a graph for one or more of these, the next ones derive one value type from the other (or a canonical ID), and the remaining steps look the same.

### Set time range  and provide instructions

Analysts unfamiliar with your template would strongly benefit from instructions telling them what to modify (if anything) and how to use the investigation. Many options likely have sane defaults on a per-template basis, such as the time range, so we recommend including them in your URLs.

### Naming

Content management can become an issue. Use a custom short description name, such as `name=%5BPhone%20360%5D%20555-5555` (=> `[Phone 360] 555-5555`. The generated investigations can now be easily searched and sorted.

### Cross-linking

You can include templates as links within templates! For example, whenever a phone number node is generated, you can include attribute `link` with value `/pivot/template?investigation=...` .
