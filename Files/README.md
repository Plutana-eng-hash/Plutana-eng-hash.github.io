# PS4 Games List

Static site for GitHub Pages. `index.html` loads the game list from Hugging Face in the browser.

## Publish on GitHub Pages
1. Create a new repository on github.com.
2. Upload `index.html` and `.nojekyll` (and `ps4_helper.py`, `README.md` if you like) to the repo root.
3. Repo **Settings > Pages > Build and deployment**: Source = *Deploy from a branch*, Branch = `main`, folder `/ (root)`. Save.
4. After a minute the site is live at `https://YOUR-USERNAME.github.io/REPO-NAME/`.

## Direct downloads
GitHub Pages only serves static files, so it cannot fetch downloads from ORBISPatches itself.
Run `python3 ps4_helper.py` on your computer and open the site in Chrome or Firefox; the Download buttons then use it.
Safari blocks pages from reaching localhost. Without the helper, each button offers a link to the game's ORBISPatches page.
To use a helper hosted elsewhere, open the site with `?helper=https://your-helper-url`.
