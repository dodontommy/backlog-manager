import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form"]
  static values = { sessionId: String }

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

  handleKeydown(event) {
    // Enter without Shift: submit form
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
    // Shift+Enter: allow default (new line)
  }

  async submit(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    // Add user message to UI
    this.addMessage("user", message)
    this.inputTarget.value = ""
    this.inputTarget.style.height = 'auto' // Reset textarea height
    this.inputTarget.disabled = true

    // Create assistant message div for streaming
    const assistantMessageDiv = this.createMessageDiv("assistant")
    const contentDiv = assistantMessageDiv.querySelector(".message-content")

    try {
      await this.streamMessage(message, contentDiv)
    } catch (error) {
      console.error("Chat error:", error)
      contentDiv.textContent = "Sorry, something went wrong. Please try again."
    } finally {
      this.inputTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  async streamMessage(message, contentDiv) {
    const url = "/chat/messages"
    const body = { message }

    if (this.sessionIdValue) {
      body.session_id = this.sessionIdValue
    }

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify(body)
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    // Read streaming response
    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let buffer = '' // Buffer for incomplete messages

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      // Append new chunk to buffer
      buffer += decoder.decode(value, { stream: true })

      // Split by SSE message delimiter
      const messages = buffer.split('\n\n')

      // Keep the last (potentially incomplete) message in buffer
      buffer = messages.pop() || ''

      // Process complete messages
      for (const message of messages) {
        if (message.startsWith('data: ')) {
          try {
            const data = JSON.parse(message.slice(6))

            if (data.type === 'session_id') {
              // Store session ID for subsequent requests
              this.sessionIdValue = data.session_id
            } else if (data.type === 'text') {
              contentDiv.textContent += data.content
              this.scrollToBottom()
            } else if (data.type === 'error') {
              contentDiv.textContent += `\n\nError: ${data.content}`
            } else if (data.type === 'done') {
              // Message complete
              return
            }
          } catch (e) {
            console.error('Failed to parse SSE message:', message, e)
          }
        }
      }
    }
  }

  addMessage(role, content) {
    const messageDiv = this.createMessageDiv(role)
    const contentDiv = messageDiv.querySelector(".message-content")
    contentDiv.textContent = content
    this.scrollToBottom()
  }

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

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
