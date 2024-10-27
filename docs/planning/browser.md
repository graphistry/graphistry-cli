# Browser Configuration & Debugging

Graphistry is optimized from Chrome (Safari, new IE) and supports Firefox

It runs on mobile and tablets, and is subject to the device memory

## Symptom: Missing nodes/edges

* Check that [WebGL 1.0 is enabled](https://webglreport.com/)
* Ensure that the window size is not too big
* Check the filter and exclude panels are not hiding data

## Symptom: The browser crashes
* Try a smaller graph
* Check that WebGL is using hardware acceleration, not software emulation
* Give the browser more JS and WebGL memory
  * In OS X: `open /Applications/Google\ Chrome.app --args --js-flags="--max_old_space_size=8192"`
* Use a client device with a dedicated GPU and more GPU memory
