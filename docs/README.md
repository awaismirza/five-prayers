# Five Prayers — Product Website

Static website for [Salah Logbook](https://salahlogbook.app), a privacy-first iOS prayer tracking app.

## Pages

| File | URL |
|---|---|
| `index.html` | `/` — Home page |
| `privacy.html` | `/privacy.html` — Privacy Policy |
| `terms.html` | `/terms.html` — Terms & Conditions |
| `support.html` | `/support.html` — Support & FAQ |

## Publish on GitHub Pages

1. Push this repository to GitHub.
2. Open the repository **Settings** tab.
3. Go to **Pages** in the left sidebar.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select branch: **main**.
6. Select folder: **/docs**.
7. Click **Save**.
8. GitHub will publish the site. The URL will be shown in the Pages settings (e.g. `https://yourusername.github.io/salah-logbook/`).

## App Store Connect URLs

Use these URLs in App Store Connect (replace `yourusername` and `your-repo`):

| Field | URL |
|---|---|
| Marketing URL | `https://yourusername.github.io/your-repo/` |
| Privacy Policy URL | `https://yourusername.github.io/your-repo/privacy.html` |
| Support URL | `https://yourusername.github.io/your-repo/support.html` |

## Placeholders to Replace

Search all HTML files for `support@salahlogbook.app` and replace with your real support email address.

## Technical Notes

- No build step required — pure static HTML/CSS.
- No external trackers, analytics, or cookies.
- No CDN dependencies — fully offline-capable once loaded.
- Responsive — works on mobile and desktop.
