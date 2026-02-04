import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form"]
  static values = { sessionId: String }

  connect() {
    console.log("Chat controller connected")
    this.scrollToBottom()
  }

  async submit(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    // Add user message to UI
    this.addMessage("user", message)
    this.inputTarget.value = ""
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
    messageDiv.classList.add("message", `message-${role}`)

    const contentDiv = document.createElement("div")
    contentDiv.classList.add("message-content")

    messageDiv.appendChild(contentDiv)
    this.messagesTarget.appendChild(messageDiv)

    return messageDiv
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
