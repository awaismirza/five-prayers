# Five Prayers — Product Website

Static website for [Five Prayers](https://awaismirza.github.io/five-prayers), a simple and private iPhone app for tracking the five daily prayers.

## Structure

The only website page is the root [../index.html](../index.html). The `docs/` folder is now only used for shared image assets referenced by that page.

## Publish on GitHub Pages

1. Push this repository to GitHub.
2. Open the repository **Settings** tab.
3. Go to **Pages** in the left sidebar.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select branch: **main**.
6. Select folder: **/(root)** so GitHub Pages serves the root `index.html` directly.
7. Click **Save**.
8. GitHub will publish the site. The URL will be shown in the Pages settings. If you use a project site, prefer a slug such as `https://yourusername.github.io/five-prayers/`.

## App Store Connect URLs

Use these URLs in App Store Connect:

| Field | URL |
|---|---|
| Marketing URL | `https://awaismirza.github.io/five-prayers` |
| Privacy Policy URL | `https://awaismirza.github.io/five-prayers/#privacy` |
| Terms & Conditions URL | `https://awaismirza.github.io/five-prayers/#terms` |
| Support URL | `https://awaismirza.github.io/five-prayers/#support` |

## Contact

Use `owaesmirza@gmail.com` as the support address.

## Technical Notes

- No build step required — pure static HTML/CSS.
- No external trackers, analytics, or cookies.
- No CDN dependencies — fully offline-capable once loaded.
- Responsive — works on mobile and desktop.
