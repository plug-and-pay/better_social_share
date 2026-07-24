# better_social_share example

A manual QA harness: one button per plugin method, pickers for test media,
and every `ShareResult` surfaced in a snackbar.

## Manual QA matrix

URL-scheme and intent behavior can only be verified on real devices with the
target apps installed. Before a release, run through:

| Target | Content | Android | iOS |
|---|---|---|---|
| WhatsApp | text | ☐ | ☐ |
| WhatsApp | text + image(s) | ☐ | ☐ (single image, no text) |
| Telegram | text / files | ☐ / ☐ | ☐ / n/a (`UNAVAILABLE`) |
| Instagram | direct message | ☐ | ☐ |
| Instagram | feed 1 image / N images | ☐ / ☐ | ☐ / ☐ (Photos permission prompt) |
| Instagram | feed with Photos permission denied | n/a | ☐ (`permissionDenied`) |
| Instagram | reels video | ☐ | ☐ |
| Instagram | story: sticker only / bg image / bg video / + attribution URL | ☐ | ☐ (no empty link sticker!) |
| Facebook | feed files | ☐ | n/a (`UNAVAILABLE`) |
| Facebook | story (same variants as IG) | ☐ | ☐ |
| Messenger | text / link | ☐ | ☐ |
| TikTok | status images / post video | ☐ / ☐ | n/a (`UNAVAILABLE`) |
| X | text / text + image | ☐ / ☐ | ☐ / text only |
| SMS | text / + attachment | ☐ | ☐ (cancel → `dismissed`) |
| System sheet | text + files, cancel → `dismissed` | ☐ | ☐ (also on iPad — popover) |
| Any target uninstalled | → `appNotInstalled`, never silence | ☐ | ☐ |

Stories need a Meta App ID (create one at developers.facebook.com) entered in
the app's text field.
