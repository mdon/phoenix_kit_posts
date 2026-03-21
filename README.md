# PhoenixKitPosts

Posts module for PhoenixKit — blog posts, tags, groups, likes, media, and scheduling.

## Installation

Add to your parent app's `mix.exs`:

```elixir
{:phoenix_kit_posts, path: "../phoenix_kit_posts"}
```

Or from Hex:

```elixir
{:phoenix_kit_posts, "~> 0.1.0"}
```

Run `mix deps.get`. The module appears in the admin panel automatically via auto-discovery.

## Features

- Post management with draft/public/unlisted/scheduled status
- Like and dislike system with counters
- Tag system with hashtag parsing
- Group collections (Pinterest-style boards)
- Media attachments with ordering
- Scheduled publishing via cron jobs
- Admin pages for posts, groups, and settings

## License

MIT
