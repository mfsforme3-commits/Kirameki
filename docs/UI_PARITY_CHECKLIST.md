# Kirameki UI Parity Checklist

Use this checklist to verify the Flutter implementation matches the original Next.js mock.

## Global
- [ ] Color palette matches Tailwind tokens (`bg-black`, `text-gray-100`, accent red #dc2626)
- [ ] Typography scale: headings, body, caps align with mock
- [ ] Motion: card hover/focus lift, nav slide-in/out, loading skeleton fade
- [ ] Custom cursor effect on desktop or equivalent focus indicator
- [ ] Dark theme default; light theme toggle available in settings
- [ ] Background gradients and particle effects approximated via Flutter shaders or animated containers

## Navigation
- [ ] Mobile bottom nav mirrors mock icons/labels
- [ ] Desktop nav transitions between hidden and sticky states on scroll
- [ ] TV DPAD focus states highlight nav elements with glow effect

## Browse Screen
- [ ] Hero section typography, CTA button styles, search bar alignment
- [ ] Genre chips styles (selected vs unselected)
- [ ] Filter drawer animation on mobile
- [ ] Grid layout card spacing (2/3/4/5 columns responsive breakpoints)
- [ ] List view layout: thumbnail size, metadata alignment, CTA button
- [ ] Loading skeleton shapes and timing

## Anime Detail
- [ ] Banner, poster overlay, gradient mask
- [ ] Metadata chips (rating, year, episodes)
- [ ] Tabs (Overview, Episodes, Related) design and transitions
- [ ] Episode list item layout (progress bar, actions)
- [ ] Related anime carousel styling

## Watch Screen
- [ ] Video player controls: play/pause, skip, replay, volume slider
- [ ] Subtitles toggle, settings panel styling
- [ ] Progress bar, intro/outro skip buttons positions
- [ ] Up-next overlay and auto-play countdown
- [ ] TV remote mappings for playback controls

## My List
- [ ] Card sizes, shimmering empty state, remove-from-list button
- [ ] Sort/search controls styling
- [ ] Continue watching row with progress rings

## Settings
- [ ] Toggle styles, section dividers, typography
- [ ] QR pairing screen visuals (QR size, glow, step instructions)

## Accessibility & Localization
- [ ] Screen reader labels for major components
- [ ] Focus order consistent with layout
- [ ] UI scales correctly at 200% text size
- [ ] RTL layout sanity check (future-proof)
