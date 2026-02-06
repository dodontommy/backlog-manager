# Chat Sidebar Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a persistent, always-visible chat sidebar that makes the AI Gaming Backlog Assistant the central interface of the application.

**Architecture:** Fixed right sidebar (400px expanded, 60px collapsed) that persists across Turbo navigation. The sidebar stays in the layout while main content swaps. Uses Stimulus for collapse/expand behavior and localStorage for state persistence.

**Tech Stack:** Rails 8, Hotwire/Turbo, Stimulus.js, Tailwind CSS

**Design Document:** `docs/plans/2026-02-04-chat-sidebar-design.md`

---

## Task 1: Update Layout Structure

**Goal:** Add sidebar container to application layout with proper Hotwire/Turbo persistence.

**Files:**
- Modify: `app/views/layouts/application.html.erb:209-214`

**Step 1: Update layout to add sidebar structure**

Replace the main content section (lines 209-214) with:

```erb
      <!-- Main Content and Chat Sidebar Container -->
      <div class="flex">
        <!-- Main Content - swapped by Turbo Drive -->
        <main id="main-content" class="flex-1 pt-20 pb-12 px-4 sm:px-6 lg:px-8 transition-all duration-300" style="margin-right: 400px;">
          <div class="container mx-auto">
            <%= yield %>
          </div>
        </main>

        <!-- Chat Sidebar - persistent, never reloads -->
        <% if logged_in? %>
          <aside id="chat-sidebar" data-controller="chat-sidebar">
            <%= render "chat/sidebar" %>
          </aside>
        <% end %>
      </div>
```

**Step 2: Verify layout renders**

Run: `bin/rails server`
Visit: `http://localhost:3000`
Expected: Page loads, sidebar partial renders (will fail since partial doesn't exist yet, that's fine)

**Step 3: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "feat(chat): add persistent sidebar container to layout"
```

---

## Task 2: Create Sidebar Partial

**Goal:** Build the sidebar component with header, messages area, and input section.

**Files:**
- Create: `app/views/chat/_sidebar.html.erb`

**Step 1: Create sidebar partial**

Create `app/views/chat/_sidebar.html.erb`:

```erb
<div class="chat-sidebar fixed top-0 right-0 h-full bg-slate-900/95 backdrop-blur-xl border-l border-slate-800/50 shadow-2xl z-40 transition-all duration-300 ease-in-out"
     data-chat-sidebar-target="sidebar"
     style="width: 400px;">

  <!-- Header -->
  <div class="chat-header flex items-center justify-between h-16 px-4 border-b border-slate-800/50 sticky top-0 bg-slate-900/95 backdrop-blur-xl z-10">
    <!-- AI Avatar and Title -->
    <div class="flex items-center space-x-3" data-chat-sidebar-target="headerContent">
      <!-- AI Avatar Icon (gradient circle) -->
      <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
        </svg>
      </div>

      <!-- Title and Status -->
      <div class="flex-1" data-chat-sidebar-target="titleSection">
        <h3 class="text-white font-semibold text-sm">Gaming Assistant</h3>
        <div class="flex items-center space-x-1">
          <div class="w-2 h-2 bg-green-500 rounded-full"></div>
          <span class="text-slate-400 text-xs">Online</span>
        </div>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="flex items-center space-x-2">
      <!-- Clear Chat Button -->
      <button type="button"
              class="p-2 text-slate-400 hover:text-white hover:bg-slate-800/50 rounded-lg transition-colors duration-200"
              data-chat-sidebar-target="clearButton"
              data-action="click->chat-sidebar#clearChat"
              title="Clear chat">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      </button>

      <!-- Collapse/Expand Toggle -->
      <button type="button"
              class="p-2 text-slate-400 hover:text-white hover:bg-slate-800/50 rounded-lg transition-colors duration-200"
              data-action="click->chat-sidebar#toggle"
              title="Collapse sidebar">
        <svg class="w-5 h-5" data-chat-sidebar-target="chevron" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </button>
    </div>
  </div>

  <!-- Messages Container -->
  <div class="chat-messages flex-1 overflow-y-auto p-4 space-y-4"
       data-controller="chat"
       data-chat-target="messages"
       data-chat-session-id-value=""
       style="height: calc(100vh - 64px - 88px);">

    <!-- Welcome Message -->
    <div class="message message-assistant flex justify-start">
      <div class="max-w-[90%] bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-blue-500/20 rounded-2xl rounded-tl-sm px-4 py-3">
        <div class="message-content text-slate-100 text-sm">
          Hi! I'm your gaming backlog assistant. I can help you explore your backlog, get recommendations, and update your game status. What would you like to know?
        </div>
      </div>
    </div>
  </div>

  <!-- Input Area -->
  <div class="chat-input-container border-t border-slate-800/50 p-4 bg-slate-900/95">
    <form data-chat-target="form" data-action="submit->chat#submit" class="relative">
      <textarea
        data-chat-target="input"
        placeholder="Ask about your backlog..."
        rows="1"
        class="w-full bg-slate-800/50 text-slate-100 placeholder-slate-500 rounded-xl px-4 py-3 pr-12 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all duration-200"
        style="max-height: 120px;"
        autocomplete="off"></textarea>

      <!-- Send Button -->
      <button type="submit"
              class="absolute bottom-2 right-2 w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center hover:scale-105 hover:brightness-110 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100">
        <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
        </svg>
      </button>
    </form>
  </div>
</div>

<!-- Collapsed State Icon (shown when sidebar is collapsed) -->
<div class="chat-sidebar-collapsed-icon hidden fixed top-20 right-4 z-40 cursor-pointer"
     data-chat-sidebar-target="collapsedIcon"
     data-action="click->chat-sidebar#toggle">
  <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center shadow-lg hover:scale-105 transition-transform duration-200">
    <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
    </svg>
  </div>
</div>
```

**Step 2: Test sidebar renders**

Run: `bin/rails server`
Visit: `http://localhost:3000` (as logged-in user)
Expected: Sidebar appears on right side with header, message area, and input

**Step 3: Commit**

```bash
git add app/views/chat/_sidebar.html.erb
git commit -m "feat(chat): create sidebar partial with header, messages, and input"
```

---

## Task 3: Create Chat Sidebar Controller

**Goal:** Implement Stimulus controller for collapse/expand functionality with localStorage persistence.

**Files:**
- Create: `app/javascript/controllers/chat_sidebar_controller.js`

**Step 1: Create Stimulus controller**

Create `app/javascript/controllers/chat_sidebar_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "headerContent", "titleSection", "clearButton", "chevron", "collapsedIcon"]

  connect() {
    console.log("Chat sidebar controller connected")

    // Load collapsed state from localStorage
    const isCollapsed = localStorage.getItem('chatSidebarCollapsed') === 'true'

    // Apply initial state based on screen size and saved preference
    if (window.innerWidth >= 1280) {
      // Desktop: expanded by default, unless user collapsed it
      if (isCollapsed) {
        this.collapse(false) // false = no animation on initial load
      }
    } else if (window.innerWidth >= 1024) {
      // Laptop: collapsed by default
      this.collapse(false)
    } else {
      // Tablet/Mobile: always collapsed
      this.collapse(false)
    }

    // Listen for window resize
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  disconnect() {
    window.removeEventListener('resize', this.resizeHandler)
  }

  toggle() {
    const isCurrentlyCollapsed = this.sidebarTarget.style.width === '60px' ||
                                  this.sidebarTarget.classList.contains('collapsed')

    if (isCurrentlyCollapsed) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  collapse(animate = true) {
    const sidebar = this.sidebarTarget
    const mainContent = document.getElementById('main-content')

    if (!animate) {
      sidebar.style.transition = 'none'
      if (mainContent) mainContent.style.transition = 'none'
    }

    // Collapse sidebar to 60px
    sidebar.style.width = '60px'
    sidebar.classList.add('collapsed')

    // Hide title and clear button
    if (this.hasTitleSectionTarget) {
      this.titleSectionTarget.classList.add('hidden')
    }
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.add('hidden')
    }

    // Flip chevron to point left
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = 'rotate(180deg)'
    }

    // Show collapsed icon
    if (this.hasCollapsedIconTarget) {
      this.collapsedIconTarget.classList.remove('hidden')
    }

    // Adjust main content margin
    if (mainContent) {
      mainContent.style.marginRight = '60px'
    }

    // Save state
    localStorage.setItem('chatSidebarCollapsed', 'true')

    // Restore transitions
    if (!animate) {
      setTimeout(() => {
        sidebar.style.transition = ''
        if (mainContent) mainContent.style.transition = ''
      }, 50)
    }
  }

  expand(animate = true) {
    const sidebar = this.sidebarTarget
    const mainContent = document.getElementById('main-content')

    if (!animate) {
      sidebar.style.transition = 'none'
      if (mainContent) mainContent.style.transition = 'none'
    }

    // Expand sidebar to 400px
    sidebar.style.width = '400px'
    sidebar.classList.remove('collapsed')

    // Show title and clear button
    if (this.hasTitleSectionTarget) {
      this.titleSectionTarget.classList.remove('hidden')
    }
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.remove('hidden')
    }

    // Reset chevron rotation
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = 'rotate(0deg)'
    }

    // Hide collapsed icon
    if (this.hasCollapsedIconTarget) {
      this.collapsedIconTarget.classList.add('hidden')
    }

    // Adjust main content margin
    if (mainContent) {
      mainContent.style.marginRight = '400px'
    }

    // Save state
    localStorage.setItem('chatSidebarCollapsed', 'false')

    // Restore transitions
    if (!animate) {
      setTimeout(() => {
        sidebar.style.transition = ''
        if (mainContent) mainContent.style.transition = ''
      }, 50)
    }
  }

  clearChat() {
    if (confirm('Clear all messages? This cannot be undone.')) {
      // Dispatch event that chat controller can listen to
      this.dispatch('clear', { bubbles: true })

      // Reload page to start fresh session
      window.location.reload()
    }
  }

  handleResize() {
    // Auto-collapse on tablet/mobile
    if (window.innerWidth < 1024) {
      const isCollapsed = this.sidebarTarget.style.width === '60px'
      if (!isCollapsed) {
        this.collapse(true)
      }
    }
  }
}
```

**Step 2: Test collapse/expand functionality**

Run: `bin/rails server`
Visit: `http://localhost:3000`
Actions:
1. Click collapse button (chevron) - sidebar should collapse to 60px
2. Click collapsed icon - sidebar should expand to 400px
3. Refresh page - sidebar should remember state
4. Resize window to tablet size - sidebar should auto-collapse

Expected: All interactions work smoothly

**Step 3: Commit**

```bash
git add app/javascript/controllers/chat_sidebar_controller.js
git commit -m "feat(chat): add sidebar controller with collapse/expand and localStorage"
```

---

## Task 4: Update Chat Controller for Sidebar Integration

**Goal:** Ensure existing chat controller works within sidebar and handles message animations.

**Files:**
- Modify: `app/javascript/controllers/chat_controller.js:110-121`

**Step 1: Update createMessageDiv for new styling**

Replace the `createMessageDiv` method (lines 110-121):

```javascript
  createMessageDiv(role) {
    const messageDiv = document.createElement("div")
    messageDiv.classList.add("message", `message-${role}`, "flex")

    // Add alignment classes
    if (role === "user") {
      messageDiv.classList.add("justify-end")
    } else {
      messageDiv.classList.add("justify-start")
    }

    // Create content wrapper with proper styling
    const contentWrapper = document.createElement("div")
    if (role === "user") {
      contentWrapper.classList.add("max-w-[85%]", "bg-slate-800", "border", "border-slate-700/50", "rounded-2xl", "rounded-tr-sm", "px-4", "py-3")
    } else {
      contentWrapper.classList.add("max-w-[90%]", "bg-gradient-to-br", "from-slate-800/50", "to-slate-900/50", "border", "border-blue-500/20", "rounded-2xl", "rounded-tl-sm", "px-4", "py-3")
    }

    const contentDiv = document.createElement("div")
    contentDiv.classList.add("message-content", "text-slate-100", "text-sm")

    contentWrapper.appendChild(contentDiv)
    messageDiv.appendChild(contentWrapper)

    // Add fade-in animation
    messageDiv.style.opacity = "0"
    messageDiv.style.transform = "translateY(8px)"
    messageDiv.style.transition = "opacity 200ms ease-out, transform 200ms ease-out"

    this.messagesTarget.appendChild(messageDiv)

    // Trigger animation
    setTimeout(() => {
      messageDiv.style.opacity = "1"
      messageDiv.style.transform = "translateY(0)"
    }, 10)

    return messageDiv
  }
```

**Step 2: Test message styling**

Run: `bin/rails server`
Visit: `http://localhost:3000`
Actions:
1. Send a message: "Show my backlog"
2. Observe user message appears on right with slate-800 background
3. Observe assistant response appears on left with gradient background
4. Messages should fade in smoothly

Expected: Messages styled according to design, smooth animations

**Step 3: Commit**

```bash
git add app/javascript/controllers/chat_controller.js
git commit -m "feat(chat): update message styling for sidebar design"
```

---

## Task 5: Add Responsive Behavior

**Goal:** Implement responsive breakpoints for desktop, laptop, tablet, and mobile.

**Files:**
- Modify: `app/views/layouts/application.html.erb:209-214` (already modified in Task 1)
- Modify: `app/views/chat/_sidebar.html.erb:1`

**Step 1: Add responsive classes to sidebar**

Update the sidebar wrapper div in `app/views/chat/_sidebar.html.erb` (line 1):

```erb
<div class="chat-sidebar fixed top-0 right-0 h-full bg-slate-900/95 backdrop-blur-xl border-l border-slate-800/50 shadow-2xl z-40 transition-all duration-300 ease-in-out md:block hidden"
     data-chat-sidebar-target="sidebar"
     style="width: 400px;">
```

**Step 2: Update mobile navigation to show Chat link**

The Chat link already exists in mobile nav (line 188 in application.html.erb), so no changes needed.

**Step 3: Test responsive behavior**

Run: `bin/rails server`
Test:
1. Desktop (≥1280px): Sidebar expanded by default
2. Laptop (1024-1279px): Sidebar collapsed by default
3. Tablet (768-1023px): Sidebar collapsed, overlay when expanded
4. Mobile (<768px): Sidebar hidden, Chat link in mobile nav

Expected: Sidebar adapts to screen size appropriately

**Step 4: Commit**

```bash
git add app/views/chat/_sidebar.html.erb
git commit -m "feat(chat): add responsive behavior for sidebar"
```

---

## Task 6: Add Keyboard Shortcuts

**Goal:** Implement keyboard shortcuts for common actions.

**Files:**
- Modify: `app/javascript/controllers/chat_sidebar_controller.js:18-29`

**Step 1: Add keyboard event listeners**

Add keyboard shortcut handling in `connect()` method after line 29:

```javascript
    // Listen for window resize
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)

    // Add keyboard shortcuts
    this.keyboardHandler = this.handleKeyboard.bind(this)
    document.addEventListener('keydown', this.keyboardHandler)
  }

  disconnect() {
    window.removeEventListener('resize', this.resizeHandler)
    document.removeEventListener('keydown', this.keyboardHandler)
  }

  handleKeyboard(event) {
    // Escape: Collapse sidebar
    if (event.key === 'Escape') {
      const isCollapsed = this.sidebarTarget.style.width === '60px'
      if (!isCollapsed) {
        this.collapse()
      }
    }

    // Cmd/Ctrl+K: Focus input
    if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
      event.preventDefault()
      const input = document.querySelector('[data-chat-target="input"]')
      if (input) {
        input.focus()
        // Expand sidebar if collapsed
        const isCollapsed = this.sidebarTarget.style.width === '60px'
        if (isCollapsed) {
          this.expand()
        }
      }
    }
  }
```

**Step 2: Test keyboard shortcuts**

Run: `bin/rails server`
Test:
1. Press Escape - sidebar collapses
2. Press Cmd+K (Mac) or Ctrl+K (Windows) - sidebar expands and input focuses

Expected: Keyboard shortcuts work as specified

**Step 3: Commit**

```bash
git add app/javascript/controllers/chat_sidebar_controller.js
git commit -m "feat(chat): add keyboard shortcuts (Escape, Cmd/Ctrl+K)"
```

---

## Task 7: Add Auto-Expand Textarea

**Goal:** Make textarea automatically expand as user types (max 4 lines).

**Files:**
- Modify: `app/javascript/controllers/chat_controller.js:6-10`

**Step 1: Add textarea auto-expand**

Add new method and connect handler to chat controller after line 10:

```javascript
  connect() {
    console.log("Chat controller connected")
    this.scrollToBottom()

    // Add auto-expand to textarea
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('input', this.autoExpand.bind(this))
    }
  }

  autoExpand(event) {
    const textarea = event.target
    // Reset height to auto to get correct scrollHeight
    textarea.style.height = 'auto'
    // Set height to scrollHeight (capped at max-height in CSS)
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px'
  }
```

**Step 2: Update submit handler to reset height**

Add height reset in `submit` method after line 20:

```javascript
    // Add user message to UI
    this.addMessage("user", message)
    this.inputTarget.value = ""
    this.inputTarget.style.height = 'auto' // Reset textarea height
    this.inputTarget.disabled = true
```

**Step 3: Test textarea auto-expand**

Run: `bin/rails server`
Test:
1. Type a long message that wraps to multiple lines
2. Textarea should expand automatically
3. After sending, textarea should reset to single line

Expected: Textarea grows/shrinks smoothly

**Step 4: Commit**

```bash
git add app/javascript/controllers/chat_controller.js
git commit -m "feat(chat): add auto-expanding textarea with max height"
```

---

## Task 8: Add Shift+Enter for New Line

**Goal:** Allow Shift+Enter to insert new line instead of sending message.

**Files:**
- Modify: `app/views/chat/_sidebar.html.erb:62-75`

**Step 1: Update form to prevent submit on Shift+Enter**

Update the textarea in sidebar partial (around line 66):

```erb
      <textarea
        data-chat-target="input"
        data-action="keydown->chat#handleKeydown"
        placeholder="Ask about your backlog..."
        rows="1"
        class="w-full bg-slate-800/50 text-slate-100 placeholder-slate-500 rounded-xl px-4 py-3 pr-12 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all duration-200"
        style="max-height: 120px;"
        autocomplete="off"></textarea>
```

**Step 2: Add handleKeydown method to chat controller**

Add method to `app/javascript/controllers/chat_controller.js` after line 11:

```javascript
  handleKeydown(event) {
    // Enter without Shift: submit form
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
    // Shift+Enter: allow default (new line)
  }
```

**Step 3: Remove form submit prevention**

The form will now be submitted via Enter key, not form submit event directly.

**Step 4: Test Shift+Enter behavior**

Run: `bin/rails server`
Test:
1. Type message and press Enter - message sends
2. Type message and press Shift+Enter - new line inserted
3. Continue typing and press Enter - message sends

Expected: Enter sends, Shift+Enter creates new line

**Step 5: Commit**

```bash
git add app/views/chat/_sidebar.html.erb app/javascript/controllers/chat_controller.js
git commit -m "feat(chat): add Shift+Enter for new line in textarea"
```

---

## Task 9: Hide Sidebar on Mobile

**Goal:** Ensure sidebar is hidden on mobile devices (<768px).

**Files:**
- Modify: `app/views/layouts/application.html.erb:215-222`

**Step 1: Update sidebar conditional to check screen size**

The responsive class `md:block hidden` was already added in Task 5. Now verify mobile users see the full-page chat view.

**Step 2: Verify mobile navigation**

The Chat link already exists in mobile nav (line 188 in application.html.erb).

**Step 3: Test mobile view**

Run: `bin/rails server`
Test:
1. Resize browser to <768px width
2. Sidebar should be hidden
3. Click "Chat" in mobile menu
4. Should navigate to `/chat` page showing full-page chat

Expected: Sidebar hidden on mobile, full-page chat accessible

**Step 4: Commit**

No changes needed - already implemented in Task 5. Skip commit.

---

## Task 10: Add CSS Custom Properties

**Goal:** Add CSS variables for sidebar widths and transitions.

**Files:**
- Create: `app/assets/stylesheets/chat_sidebar.css`

**Step 1: Create chat sidebar CSS file**

Create `app/assets/stylesheets/chat_sidebar.css`:

```css
:root {
  --sidebar-width-expanded: 400px;
  --sidebar-width-collapsed: 60px;
  --sidebar-transition-duration: 300ms;
}

/* Custom scrollbar for chat messages */
.chat-messages::-webkit-scrollbar {
  width: 6px;
}

.chat-messages::-webkit-scrollbar-track {
  background: rgba(30, 41, 59, 0.5);
  border-radius: 3px;
}

.chat-messages::-webkit-scrollbar-thumb {
  background: rgba(71, 85, 105, 0.8);
  border-radius: 3px;
}

.chat-messages::-webkit-scrollbar-thumb:hover {
  background: rgba(71, 85, 105, 1);
}

/* Smooth transitions */
.chat-sidebar,
#main-content {
  transition: all var(--sidebar-transition-duration) ease-in-out;
}

/* Typing indicator animation */
@keyframes bounce {
  0%, 80%, 100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-8px);
  }
}

.typing-indicator span {
  animation: bounce 1.4s infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

/* Message entrance animation */
.message {
  animation: fadeInUp 200ms ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Responsive: Hide sidebar on mobile */
@media (max-width: 767px) {
  .chat-sidebar {
    display: none !important;
  }

  #main-content {
    margin-right: 0 !important;
  }
}

/* Tablet: Overlay behavior */
@media (min-width: 768px) and (max-width: 1023px) {
  .chat-sidebar:not(.collapsed) {
    box-shadow: -4px 0 24px rgba(0, 0, 0, 0.5);
  }
}
```

**Step 2: Verify CSS is loaded**

CSS should be automatically loaded via `stylesheet_link_tag :app` in layout.

**Step 3: Test styling**

Run: `bin/rails server`
Test:
1. Scroll messages - custom scrollbar appears
2. Send message - fade-in animation plays
3. Collapse/expand - smooth transitions

Expected: All CSS effects work

**Step 4: Commit**

```bash
git add app/assets/stylesheets/chat_sidebar.css
git commit -m "feat(chat): add CSS custom properties and animations"
```

---

## Task 11: Integration Testing

**Goal:** Verify all features work together across different scenarios.

**Files:**
- Test manually (no code changes)

**Step 1: Test complete flow on desktop**

Run: `bin/rails server`
Test sequence:
1. Visit homepage as logged-in user
2. Sidebar appears expanded (400px)
3. Send a test message: "Show my backlog"
4. Message appears styled correctly
5. Response streams in character-by-character
6. Click collapse button
7. Sidebar collapses to 60px
8. Main content adjusts margin
9. Click collapsed icon
10. Sidebar expands back to 400px
11. Navigate to Games page
12. Sidebar persists, doesn't reload
13. Messages still visible
14. Refresh page
15. Sidebar remembers collapsed/expanded state

Expected: All interactions work smoothly, no console errors

**Step 2: Test on laptop screen size**

Resize browser to 1024px-1279px:
1. Sidebar starts collapsed (60px)
2. Can expand when needed
3. State persists across navigation

Expected: Laptop breakpoint works correctly

**Step 3: Test on tablet screen size**

Resize browser to 768px-1023px:
1. Sidebar collapsed by default
2. Expanding shows overlay with shadow
3. Click outside might dismiss (depends on implementation)

Expected: Tablet overlay behavior works

**Step 4: Test on mobile screen size**

Resize browser to <768px:
1. Sidebar completely hidden
2. Main content full width
3. "Chat" link appears in mobile nav
4. Clicking navigates to `/chat` page

Expected: Mobile hides sidebar, full-page chat accessible

**Step 5: Test keyboard shortcuts**

Test:
1. Press Escape - collapses sidebar
2. Press Cmd/Ctrl+K - focuses input, expands sidebar

Expected: Keyboard shortcuts function correctly

**Step 6: Document any issues**

If any issues found, create follow-up tasks.

Expected: Zero critical bugs, smooth UX

**Step 7: Mark complete**

No commit needed - this is a testing task.

---

## Task 12: Final Polish and Cleanup

**Goal:** Remove old chat page view, clean up unused code, run tests.

**Files:**
- Modify: `app/views/chat/index.html.erb`
- Modify: `app/views/chat/_chat_widget.html.erb` (can be removed if not used)

**Step 1: Simplify chat index for mobile**

Update `app/views/chat/index.html.erb` to be mobile-optimized:

```erb
<div class="max-w-4xl mx-auto">
  <div class="bg-slate-800/50 backdrop-blur-xl rounded-lg border border-slate-700/50 shadow-xl overflow-hidden">
    <!-- Header -->
    <div class="bg-slate-900/50 border-b border-slate-700/50 px-6 py-4">
      <div class="flex items-center space-x-3">
        <div class="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
          <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
          </svg>
        </div>
        <div>
          <h1 class="text-xl font-bold text-white">Gaming Backlog Assistant</h1>
          <div class="flex items-center space-x-1">
            <div class="w-2 h-2 bg-green-500 rounded-full"></div>
            <span class="text-slate-400 text-sm">Online</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Chat Widget (reuse existing partial structure) -->
    <div data-controller="chat" data-chat-session-id-value="" class="bg-slate-900/30">
      <!-- Messages -->
      <div class="chat-messages p-6 space-y-4" data-chat-target="messages" style="height: calc(100vh - 280px); overflow-y: auto;">
        <div class="message message-assistant flex justify-start">
          <div class="max-w-[90%] bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-blue-500/20 rounded-2xl rounded-tl-sm px-4 py-3">
            <div class="message-content text-slate-100 text-sm">
              Hi! I'm your gaming backlog assistant. I can help you explore your backlog, get recommendations, and update your game status. What would you like to know?
            </div>
          </div>
        </div>
      </div>

      <!-- Input -->
      <div class="border-t border-slate-700/50 p-6">
        <form data-chat-target="form" data-action="submit->chat#submit" class="relative">
          <textarea
            data-chat-target="input"
            data-action="keydown->chat#handleKeydown input->chat#autoExpand"
            placeholder="Ask about your backlog..."
            rows="1"
            class="w-full bg-slate-800/50 text-slate-100 placeholder-slate-500 rounded-xl px-4 py-3 pr-12 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all duration-200"
            style="max-height: 120px;"
            autocomplete="off"></textarea>

          <button type="submit"
                  class="absolute bottom-2 right-2 w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center hover:scale-105 hover:brightness-110 transition-all duration-200">
            <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
          </button>
        </form>
      </div>
    </div>
  </div>
</div>
```

**Step 2: Run all tests**

```bash
bin/rails test
```

Expected: All tests pass (92 runs, 0 failures, 1 skip)

**Step 3: Run linter**

```bash
bundle exec rubocop
```

Expected: No new offenses

**Step 4: Verify in browser**

Final walkthrough:
1. Desktop: Sidebar persistent, smooth interactions
2. Mobile: Full-page chat works
3. All features functional

Expected: Production-ready

**Step 5: Commit**

```bash
git add app/views/chat/index.html.erb
git commit -m "feat(chat): update mobile chat page to match sidebar design"
```

---

## Task 13: Final Verification and Documentation

**Goal:** Run final tests, ensure all success criteria are met, update documentation.

**Files:**
- Test: Run full test suite
- Verify: All success criteria from design document

**Step 1: Run full test suite**

```bash
bin/rails test
```

Expected: All tests pass

**Step 2: Verify success criteria**

Check against design document `docs/plans/2026-02-04-chat-sidebar-design.md`:

- ✅ Sidebar persists across all Turbo navigation
- ✅ Messages stay visible when navigating between pages
- ✅ Collapse/expand works smoothly with localStorage
- ✅ New messages animate in elegantly
- ✅ Streaming text appears (existing SSE implementation)
- ✅ Responsive behavior works on all breakpoints
- ✅ Keyboard shortcuts function correctly
- ✅ Mobile users see full-page chat experience
- ✅ Design matches existing slate/blue/purple theme
- ✅ No performance issues with DOM persistence

**Step 3: Update design document status**

Update `docs/plans/2026-02-04-chat-sidebar-design.md` header:

```markdown
**Date:** 2026-02-04
**Status:** ✅ Complete - Implemented in feature/chat-sidebar
**Type:** Feature Addition
```

**Step 4: Commit documentation update**

```bash
git add docs/plans/2026-02-04-chat-sidebar-design.md
git commit -m "docs(chat): mark sidebar design as complete"
```

**Step 5: Ready for review**

Implementation complete. Ready for:
1. Code review
2. User testing
3. Merge to main branch

---

## Success Criteria Checklist

All tasks complete when:

- [x] Sidebar added to application layout with Turbo persistence
- [x] Sidebar partial created with header, messages, and input
- [x] Chat sidebar controller implements collapse/expand
- [x] localStorage persists collapse state across sessions
- [x] Chat controller updated with new message styling
- [x] Responsive behavior works for desktop/laptop/tablet/mobile
- [x] Keyboard shortcuts (Escape, Cmd/Ctrl+K) implemented
- [x] Textarea auto-expands with max height
- [x] Shift+Enter inserts new line (Enter sends)
- [x] CSS custom properties and animations added
- [x] Mobile view hides sidebar, shows full-page chat
- [x] All tests passing
- [x] Design document updated to "Complete" status

## Notes

- Existing SSE streaming backend works without changes
- Chat controller already handles message sending/receiving
- Hotwire/Turbo integration provides seamless navigation
- DRY: Reused existing chat controller for message logic
- YAGNI: Skipped typing indicator (can add later if needed)
- TDD: No new backend logic, so no new backend tests needed (all frontend)

## Future Enhancements

See "Future Enhancements" section in design document for ideas:
- Typing indicator with animated dots
- Message timestamps on hover
- Error retry buttons
- Suggested prompts when chat is empty
- "New Chat" button functionality
