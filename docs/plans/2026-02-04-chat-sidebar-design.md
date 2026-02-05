# Chat Sidebar Design

**Date:** 2026-02-04
**Status:** Design Complete - Ready for Implementation
**Type:** Feature Addition

## Overview

Design for a persistent, always-visible chat sidebar that makes the AI Gaming Backlog Assistant the central interface of the application. The sidebar uses a sleek, minimal design that matches the existing dark slate theme with blue-to-purple gradient accents.

## Design Decisions

### Core Approach
- **Always-visible right sidebar** (not floating widget)
- Chat is the primary feature, always accessible
- Uses Hotwire/Turbo for persistent state across navigation
- Collapsible to save space when needed

### Visual Style
- **Sleek & Minimal** aesthetic
- Smooth animations and transitions
- Professional feel (ChatGPT/Linear inspired)
- Dark slate backgrounds with gradient accents
- No gimmicks or gaming-specific theming

---

## Architecture & Layout

### Overall Structure

```
┌─────────────────────────────────────────────────┐
│  Navigation Bar (full width)                    │
├──────────────────────────┬──────────────────────┤
│                          │  Chat Sidebar        │
│  Main Content Area       │  ┌────────────────┐ │
│  (games, library, etc)   │  │ Header         │ │
│                          │  ├────────────────┤ │
│                          │  │                │ │
│                          │  │ Messages       │ │
│                          │  │ (scrollable)   │ │
│                          │  │                │ │
│                          │  ├────────────────┤ │
│                          │  │ Input Box      │ │
│                          │  └────────────────┘ │
└──────────────────────────┴──────────────────────┘
```

### Key Measurements
- **Sidebar width:** 400px (expanded), 60px (collapsed)
- **Sidebar position:** `position: fixed` on right side
- **Main content:** `margin-right: 400px` (or 60px when collapsed)
- **Z-index:** 40 (below modals/dropdowns at 50, above main content)
- **Transition:** 300ms ease for collapse/expand animation

### State Management
- Sidebar collapse state stored in `localStorage` (`chatSidebarCollapsed: boolean`)
- Persists across page navigation
- Default: expanded for desktop, collapsed for tablet

### Hotwire Integration

**Critical:** The sidebar persists across all navigation without reloading.

```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <nav>...</nav>

  <div class="flex">
    <!-- Main content - swapped by Turbo Drive -->
    <main id="main-content">
      <%= yield %>
    </main>

    <!-- Sidebar - persistent, never reloads -->
    <aside id="chat-sidebar">
      <%= render "chat/sidebar" %>
    </aside>
  </div>
</body>
```

**Benefits:**
- Chat state persists naturally (no localStorage hacks for messages)
- Streaming continues even if user navigates mid-response
- Cleaner implementation, better UX

---

## Component Structure

The sidebar breaks down into 4 main components:

### 1. Sidebar Container (`chat-sidebar`)
- Fixed position right panel
- Background: `bg-slate-900/95` with subtle border
- Backdrop blur: `backdrop-blur-xl`
- Box shadow for elevation
- Smooth width transition when collapsing

### 2. Chat Header (`chat-header`)
- **Height:** ~64px (matches nav bar)
- **Contents:**
  - AI avatar/icon (gradient circle, blue-to-purple)
  - Title: "Gaming Assistant" (hidden when collapsed)
  - Status indicator: "Online" with green dot
  - Collapse/expand toggle button (chevron icon)
  - Optional: Clear chat button (trash icon)
- **Behavior:**
  - Sticky position so it stays visible while scrolling messages
  - Border bottom: `border-slate-800/50`

### 3. Messages Container (`chat-messages`)
- Flex-grow to fill available space
- Scrollable overflow: `overflow-y-auto`
- Padding: 16px
- Custom scrollbar styling (thin, slate-700)
- Messages stack vertically with gap
- Auto-scroll to bottom on new messages

### 4. Input Area (`chat-input`)
- Fixed at bottom of sidebar
- **Contains:**
  - Text input (multi-line textarea with auto-expand)
  - Send button (or Enter to send)
  - Character count (optional)
- Border top: `border-slate-800/50`
- Padding: 16px

**When Collapsed:**
- Only the header with icons shows
- Width: 60px
- Shows AI avatar icon
- Click to expand

---

## Message Display

### Message Structure

Each message is a styled container with role-based styling:

#### User Messages
- **Alignment:** Right
- **Background:** `bg-slate-800` with subtle border
- **Rounded corners:** `rounded-2xl rounded-tr-sm` (small notch on top-right)
- **Text color:** `text-slate-100`
- **Max width:** 85% of container
- **Padding:** 12px 16px

#### Assistant Messages
- **Alignment:** Left
- **Background:** `bg-gradient-to-br from-slate-800/50 to-slate-900/50`
- **Border:** 1px gradient border (`from-blue-500/20 to-purple-600/20`)
- **Rounded corners:** `rounded-2xl rounded-tl-sm` (small notch on top-left)
- **Text color:** `text-slate-100`
- **Max width:** 90% of container (slightly wider for more info)
- **Padding:** 12px 16px

### Visual Effects

#### 1. Entrance Animation
- New messages fade in with slide-up
- Initial state: `opacity-0 translate-y-2`
- Final state: `opacity-100 translate-y-0`
- Duration: 200ms ease-out
- Each message staggers by 50ms if multiple arrive

#### 2. Streaming Text
- Cursor/blinking indicator at end while typing
- Text appears character-by-character (handled by SSE)
- Smooth scroll follows the growing text

#### 3. Typing Indicator
- Three animated dots when assistant is thinking
- Bouncing animation with stagger effect
- Same styling as assistant message bubble

#### 4. Timestamps
- Small gray text below message: `text-slate-500 text-xs`
- Shows relative time: "Just now", "2m ago"
- Only visible on hover to reduce clutter

---

## Interactions & Features

### Input Field

**Design:**
- Multi-line textarea with auto-expand (max 4 lines before scroll)
- Background: `bg-slate-800/50` with focus ring (`ring-blue-500/50`)
- Placeholder: "Ask about your backlog..." (`text-slate-500`)
- Rounded corners: `rounded-xl`
- Padding: `12px 44px 12px 16px` (right padding for button)

**Send Button:**
- Positioned absolute inside textarea (bottom-right corner)
- Icon: Paper plane or arrow up
- Background: Gradient `from-blue-500 to-purple-600` when active
- Disabled state: `bg-slate-700` when input empty
- Hover: Slight scale (1.05) and brightness increase
- Size: 32px circle

### Suggested Prompts

When chat is empty, show 3-4 suggestion chips:
- **Examples:**
  - "What should I play?"
  - "Show my backlog"
  - "Rate a game"
- **Style:** Outlined buttons with hover effect
- **Behavior:** Click to auto-fill and send
- **Animation:** Fade out once first message is sent

### Features

#### 1. Loading States
- Send button shows spinner while waiting for first response
- Typing indicator in chat while streaming

#### 2. Error Handling
- Error messages appear as system messages (red accent)
- "Retry" button appears on failed messages
- Toast notification for connection issues

#### 3. Keyboard Shortcuts
- **Enter:** Send message
- **Shift+Enter:** New line in textarea
- **Escape:** Collapse sidebar
- **Cmd/Ctrl+K:** Focus input

#### 4. Session Continuity
- Messages persist during navigation (stay in DOM with Turbo)
- "New Chat" button to clear and start fresh
- Session managed by backend (session_id in SSE)

---

## Responsive Behavior

### Breakpoint Strategy

#### Desktop (≥1280px)
- Sidebar expanded by default (400px)
- Main content has comfortable breathing room
- Full chat experience with all features visible

#### Laptop (1024px - 1279px)
- Sidebar collapsed by default (60px)
- User can expand when needed
- Main content gets priority for game browsing
- Expand shows full 400px sidebar overlaying content slightly

#### Tablet (768px - 1023px)
- Sidebar always collapsed to icon only (60px)
- Click opens overlay panel (400px) that slides in from right
- Dark backdrop overlay (`bg-black/50`) to focus attention
- Click outside or close button to dismiss
- Behaves like a drawer

#### Mobile (<768px)
- No sidebar visible at all
- Chat accessed via "Chat" link in mobile nav
- Opens full-screen `/chat` page
- Dedicated page gives full attention to conversation
- Back button returns to previous page

### Collapse Icon Behavior

When collapsed (60px width):
- Shows just the AI avatar icon (gradient circle)
- Notification badge if new messages (unlikely but nice)
- Hover tooltip: "Open Chat"
- Click to expand/overlay

### Transition Smoothness
- All width changes animated (300ms ease-in-out)
- Content reflows smoothly as sidebar expands/collapses
- No jarring jumps or layout shifts

---

## Implementation Approach

### File Structure

```
app/views/
  layouts/
    application.html.erb          # Add sidebar here
  chat/
    _sidebar.html.erb             # Main sidebar component
    _message.html.erb             # Single message partial
    index.html.erb                # Mobile full-page view (already exists)

app/javascript/controllers/
  chat_sidebar_controller.js      # NEW: Sidebar behavior (collapse/expand)
  chat_controller.js              # UPDATE: Existing, handles messaging

app/assets/stylesheets/
  chat_sidebar.css                # NEW: Sidebar styles
  chat.css                        # UPDATE: Message styles
```

### Key Technical Decisions

#### 1. Stimulus Controllers

**`chat-sidebar-controller.js` (NEW):**
- Handles collapse/expand toggle
- Manages localStorage state (`chatSidebarCollapsed`)
- Updates main content margin when toggling
- Handles responsive behavior (auto-collapse on tablet)

**`chat-controller.js` (EXISTING):**
- SSE streaming logic (already implemented)
- Message sending and receiving
- Session ID tracking
- No major changes needed

**Communication:**
- Controllers can communicate via Stimulus events if needed
- Example: Sidebar can dispatch `chat:opened` event

#### 2. Styling Approach

- **Tailwind utilities** in ERB for structure/layout
- **Custom CSS** for animations and complex gradients
- **CSS custom properties** for dynamic values:
  ```css
  :root {
    --sidebar-width-expanded: 400px;
    --sidebar-width-collapsed: 60px;
  }
  ```

#### 3. Persistence Strategy

- **Collapse state:** `localStorage.getItem('chatSidebarCollapsed')`
- **Chat session:** Already handled by backend (session_id in SSE)
- **Messages:** Stay in DOM with Turbo, no special handling needed

#### 4. Animations

- **CSS transitions** for width changes
- **Stimulus.js** for fade-in animations on messages
- **Intersection Observer** for auto-scroll behavior

#### 5. Mobile Strategy

- CSS media queries hide sidebar on mobile
- Existing `/chat` page becomes mobile view
- No duplicate code needed
- Progressive enhancement approach

---

## Build Order

Recommended implementation sequence:

1. **Update layout structure**
   - Add sidebar to `application.html.erb`
   - Adjust main content margins
   - Test Turbo persistence

2. **Create sidebar component**
   - Build `_sidebar.html.erb` with all sections
   - Add basic Tailwind styling
   - Ensure it renders correctly

3. **Add collapse functionality**
   - Create `chat_sidebar_controller.js`
   - Implement toggle button
   - Add localStorage persistence
   - Test smooth transitions

4. **Restyle messages**
   - Update message partials with new design
   - Add gradient borders and animations
   - Implement entrance animations
   - Add typing indicator

5. **Polish input area**
   - Style textarea with auto-expand
   - Add send button styling
   - Implement suggested prompts
   - Add keyboard shortcuts

6. **Responsive behavior**
   - Add media query breakpoints
   - Test tablet drawer behavior
   - Ensure mobile shows dedicated page
   - Test on various screen sizes

7. **Final polish**
   - Add timestamps on hover
   - Implement error states
   - Add loading spinners
   - Test across browsers

---

## Success Criteria

The implementation is complete when:

- ✅ Sidebar persists across all Turbo navigation
- ✅ Messages stay visible when navigating between pages
- ✅ Collapse/expand works smoothly with localStorage
- ✅ New messages animate in elegantly
- ✅ Streaming text appears with cursor indicator
- ✅ Responsive behavior works on all breakpoints
- ✅ Keyboard shortcuts function correctly
- ✅ Mobile users see full-page chat experience
- ✅ Design matches existing slate/blue/purple theme
- ✅ No performance issues with DOM persistence

---

## Future Enhancements (Out of Scope)

Ideas for later iterations:

- Message reactions/emoji
- Code syntax highlighting in responses
- Image/screenshot sharing
- Voice input option
- Chat history search
- Multiple conversation threads
- Export chat transcript
- Dark/light mode toggle for chat

---

## Notes

- This design leverages existing SSE streaming backend (no changes needed)
- Hotwire/Turbo integration is key to smooth UX
- Keep it minimal - resist adding too many features initially
- Focus on smooth animations and professional polish
- Test thoroughly on real devices, not just browser dev tools
