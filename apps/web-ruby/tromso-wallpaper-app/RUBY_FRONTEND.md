# Ruby Frontend with ERB

This document explains how Ruby handles frontend rendering in this application using ERB (Embedded Ruby) templates.

## What is ERB?

**ERB** (Embedded Ruby) is Ruby's built-in templating system that lets you embed Ruby code directly into HTML. It's similar to:
- PHP's `<?php ?>` tags
- JSP's `<% %>` tags
- EJS in Node.js

## How It Works

### The Flow

```
1. Browser requests http://localhost:6001/
                    ↓
2. Sinatra routes to: get '/' do
                    ↓
3. Ruby executes:  erb :index, layout: :layout
                    ↓
4. Processes layout.erb (wraps content)
                    ↓
5. Inserts index.erb at <%= yield %>
                    ↓
6. Returns complete HTML to browser
                    ↓
7. Browser executes JavaScript
                    ↓
8. JavaScript fetches wallpapers from Ruby API
```

### File Structure

```
views/
├── layout.erb    # Main HTML wrapper (head, body, styles)
└── index.erb     # Page content (wallpaper app HTML + JS)
```

## ERB vs React: Key Differences

| Aspect | ERB (Ruby) | React (Node.js) |
|--------|-----------|----------------|
| **Rendering** | Server-side | Client-side |
| **Build Step** | None | Required (Vite/Webpack) |
| **Dependencies** | None | node_modules (~100MB) |
| **Language** | HTML + Ruby | JSX/TSX |
| **State** | JavaScript | React hooks |
| **Deploy** | Just Ruby | Ruby + Node.js |

## The Code

### app.rb (Sinatra Routes)

```ruby
class TromsoWallpaperApp < Sinatra::Base
  configure do
    set :views, File.join(root, '..', 'views')  # Tell Sinatra where templates are
  end

  # Serve homepage
  get '/' do
    erb :index, layout: :layout
    # Renders views/index.erb inside views/layout.erb
  end

  # API endpoints (same as before)
  get '/maramboi' do
    json THEME_LIBRARY
  end

  get '/ngorongoro' do
    # Returns wallpaper image
  end
end
```

### views/layout.erb (HTML Wrapper)

```erb
<!DOCTYPE html>
<html>
<head>
  <title>Tromso Wallpaper - Ruby Edition</title>
  <style>
    /* CSS here */
  </style>
</head>
<body>
  <%= yield %>  <!-- This is where index.erb gets inserted -->
</body>
</html>
```

The `<%= yield %>` tag is where the content from `index.erb` gets inserted.

### views/index.erb (Page Content)

```erb
<!-- HTML Structure -->
<div id="wallpaper-container">
  <img id="wallpaper-img" alt="Wallpaper">
</div>

<div id="controls">
  <select id="theme-select">
    <option value="default1">Default 1</option>
    <option value="default2">Default 2</option>
  </select>
</div>

<!-- JavaScript (vanilla, no build needed) -->
<script>
  // State management
  const state = {
    theme: 'default2',
    cache: [],
    index: -1
  };

  // Load wallpaper from API
  function loadNewImage() {
    const url = `http://192.168.1.111:8080/ngorongoro?a=tweb&d=1920x1080&t=${state.theme}`;
    const img = new Image();
    img.onload = () => {
      document.getElementById('wallpaper-img').src = img.src;
    };
    img.src = url;
  }

  // Initialize on page load
  loadNewImage();
</script>
```

## ERB Features You Can Use

### 1. Output Ruby Code

```erb
<h1>Welcome <%= username %>!</h1>
<!-- Outputs: Welcome John! -->
```

### 2. Execute Ruby (no output)

```erb
<% themes = ['nature', 'urban', 'abstract'] %>

<select>
  <% themes.each do |theme| %>
    <option value="<%= theme %>"><%= theme.capitalize %></option>
  <% end %>
</select>
```

Renders:
```html
<select>
  <option value="nature">Nature</option>
  <option value="urban">Urban</option>
  <option value="abstract">Abstract</option>
</select>
```

### 3. Pass Data from Routes

```ruby
# app.rb
get '/' do
  @username = "John"
  @themes = ['nature', 'urban']
  erb :index
end
```

```erb
<!-- views/index.erb -->
<h1>Hello <%= @username %>!</h1>
<% @themes.each do |theme| %>
  <p><%= theme %></p>
<% end %>
```

### 4. Conditionals

```erb
<% if logged_in? %>
  <a href="/logout">Logout</a>
<% else %>
  <a href="/login">Login</a>
<% end %>
```

## Why Use ERB Instead of React?

### Advantages

1. **No Build Step**
   - Change ERB → Refresh browser → See changes
   - No `npm run build`, no waiting

2. **Simpler Stack**
   - Just Ruby, no Node.js
   - No package.json, node_modules, webpack config

3. **Better for Ruby Developers**
   - Same language for backend and frontend
   - Ruby helpers, partials, layouts

4. **Faster Initial Load**
   - Server sends complete HTML
   - No "waiting for JS to load and render"

5. **Better SEO**
   - Search engines see complete HTML
   - No JavaScript required for initial render

### When to Use React Instead

- **Complex UI state** - Many interactive components
- **Real-time updates** - Chat apps, live dashboards
- **Mobile app** - React Native compatibility
- **Large team** - Frontend/backend separation
- **Heavy client-side logic** - Complex calculations, offline mode

## This App's Choice: Hybrid Approach

We use **ERB for structure + Vanilla JS for interactivity**:

```
ERB (server)                  JavaScript (client)
─────────────                 ────────────────────
HTML structure        →       DOM manipulation
CSS styling          →       Event handling
Layout/templates     →       API calls
                             State management
                             Image caching
```

### Why This Works

1. **Simple state** - Just theme, dimension, pause
2. **Image slideshow** - Perfect for vanilla JS
3. **API calls** - fetch() is built into browsers
4. **No complex UI** - Just image + controls
5. **No routing** - Single page app

## File Serving

```ruby
configure do
  set :public_folder, File.join(root, '..', 'public')
  set :static, true
end
```

Files in `public/` are served automatically:
- `public/tromso.png` → `http://localhost:6001/tromso.png`
- `public/style.css` → `http://localhost:6001/style.css`

## Development Workflow

1. **Edit ERB template**
   ```bash
   vim views/index.erb
   ```

2. **Refresh browser** (if using `rake dev` with rerun)
   - Changes auto-reload!

3. **That's it!**
   - No build step
   - No compilation
   - No bundling

Compare to React:
```bash
1. Edit src/App.tsx
2. Wait for Vite to rebuild
3. Browser hot-reloads
4. Maybe clear cache
5. Maybe rebuild everything
```

## Adding Ruby Data to Views

### Example: Theme Library from Database

```ruby
# app.rb
THEME_LIBRARY = [
  { Label: 'Nature', Config: '/nature;;#green#' },
  { Label: 'Urban', Config: '/urban;;#city#' }
]

get '/' do
  @themes = THEME_LIBRARY
  erb :index
end
```

```erb
<!-- views/index.erb -->
<select id="theme-select">
  <% @themes.each do |theme| %>
    <option value="<%= theme[:Config] %>">
      <%= theme[:Label] %>
    </option>
  <% end %>
</select>
```

**Benefits:**
- Single source of truth (Ruby constant)
- No duplicate data in JS
- Server can fetch from database
- Easy to add authentication, permissions

## Performance Comparison

### ERB (This App)

```
Request → Sinatra → Render ERB (1-5ms) → HTML (5KB) → Browser → Done
```

**Total:** ~10-20ms to first paint

### React (Previous Version)

```
Request → Sinatra → index.html (500B) → Browser
  → Download bundle.js (150KB) → Parse JS (50-100ms)
  → React renders → Fetch API → Display
```

**Total:** ~200-500ms to first paint (depending on network)

## Debugging

### View Rendered HTML

```bash
curl http://localhost:6001/
```

Shows exact HTML sent to browser.

### Check ERB Syntax

```ruby
require 'erb'
template = ERB.new(File.read('views/index.erb'))
puts template.result
```

### Ruby Errors in Views

```erb
<%= some_undefined_variable %>
```

Shows helpful error:
```
NameError at /
undefined local variable or method `some_undefined_variable'
```

## Adding Partials

Break up large templates:

```ruby
# app.rb
helpers do
  def render_partial(name)
    erb :"partials/#{name}", layout: false
  end
end
```

```erb
<!-- views/index.erb -->
<%= render_partial :header %>
<%= render_partial :wallpaper_container %>
<%= render_partial :controls %>
```

```
views/
├── layout.erb
├── index.erb
└── partials/
    ├── _header.erb
    ├── _wallpaper_container.erb
    └── _controls.erb
```

## Summary

✅ **ERB is Ruby's templating engine**
- Mix Ruby code with HTML using `<% %>` and `<%= %>`

✅ **Server-side rendering**
- Ruby generates complete HTML on the server
- Browser receives finished page

✅ **No build step needed**
- Edit → Save → Refresh
- Perfect for Ruby developers

✅ **Can use vanilla JavaScript**
- For client-side interactivity
- No framework needed for simple apps

✅ **This app uses hybrid approach**
- ERB for HTML structure and layout
- Vanilla JS for wallpaper slideshow logic
- Ruby API for wallpaper data

This is **true full-stack Ruby development** - Ruby handles both backend API and frontend HTML rendering!
