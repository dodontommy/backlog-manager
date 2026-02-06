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
